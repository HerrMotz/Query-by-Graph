mod utils;

use crate::utils::set_panic_hook;
use serde::{Deserialize, Serialize};
use serde_json::{from_str, to_string};
use spargebra::algebra::GraphPattern;
use spargebra::term::TriplePattern;
use spargebra::{Query, SparqlSyntaxError};
use std::collections::HashSet;
use wasm_bindgen::prelude::*;

const INDENTATION_COUNT: usize = 4;
const WIKIBASE_PREFIX: &str = "PREFIX wikibase: <http://wikiba.se/ontology#>";
const BD_PREFIX: &str = "PREFIX bd: <http://www.bigdata.com/rdf#>";

#[derive(Serialize, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct Entity {
    pub id: String,
    pub label: String,
    pub prefix: Prefix,
    #[serde(default = "default_selected_for_projection")]
    pub selected_for_projection: bool,
}

#[derive(Serialize, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct Property {
    pub id: String,
    pub label: String,
    pub prefix: Prefix,
    #[serde(default = "default_selected_for_projection")]
    pub selected_for_projection: bool,
    #[serde(default)]
    pub properties: Vec<Property>,
    #[serde(default)]
    pub path_type: Option<String>,
    #[serde(default)]
    pub modifier: Option<String>,
}

fn default_selected_for_projection() -> bool {
    true // Default to true for backward compatibility
}

#[derive(Serialize, Deserialize, Clone, Eq, Hash, PartialEq)]
#[serde(rename_all = "camelCase")]
pub struct Prefix {
    iri: String,
    abbreviation: String,
}

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Connection {
    pub source: Entity,
    pub target: Entity,
    pub properties: Vec<Property>,
}

// wasm method, to get a string containing a JSON, which converts it to Connection
// structs and then calls graph_to_query
#[wasm_bindgen]
pub fn vqg_to_query_wasm(
    json: &str,
    add_label_service: bool,
    add_label_service_prefixes: bool,
) -> String {
    // for better errors logging in the web browser
    set_panic_hook();

    let connections: Vec<Connection> = from_str(json).unwrap();
    vqg_to_query(connections, add_label_service, add_label_service_prefixes)
}

fn get_iri(id: &str, prefix: &Prefix) -> String {
    if prefix.iri.is_empty() {
        id.to_string()
    } else if id.contains(':') || id.starts_with('<') {
        id.to_string()
    } else {
        format!("{}:{}", prefix.abbreviation, id)
    }
}

fn generate_property_path(property: &Property) -> String {
    let iri = get_iri(&property.id, &property.prefix);

    let mut path = if !property.properties.is_empty() {
        let parts: Vec<String> = property
            .properties
            .iter()
            .map(|p| generate_property_path(p))
            .collect();
        let separator = match property.path_type.as_deref() {
            Some("alternation") => "|",
            _ => "/",
        };
        format!("({})", parts.join(separator))
    } else {
        iri
    };

    if let Some(m) = &property.modifier {
        path = format!("({}{})", path, m);
    }

    path
}

fn vqg_to_query(
    connections: Vec<Connection>,
    add_service_statement: bool,
    add_label_service_prefixes: bool,
) -> String {
    let indentation = " ".repeat(INDENTATION_COUNT);

    if connections.is_empty() {
        String::from("")
    } else {
        fn collect_vars_from_property(property: &Property, add_service_statement: bool) -> Vec<String> {
            let mut vars = Vec::new();
            if property.id.starts_with('?') && property.selected_for_projection {
                let var = property.id.clone();
                vars.push(var.clone());
                if add_service_statement {
                    vars.push(format!("?{}Label", var.trim_start_matches('?')));
                }
            }
            for p in &property.properties {
                vars.extend(collect_vars_from_property(p, add_service_statement));
            }
            vars
        }

        fn collect_prefixes_from_property(property: &Property) -> Vec<Prefix> {
            let mut prefixes = Vec::new();
            if !property.prefix.iri.is_empty() {
                prefixes.push(property.prefix.clone());
            }
            for p in &property.properties {
                prefixes.extend(collect_prefixes_from_property(p));
            }
            prefixes
        }

        let projection_set = connections
            .iter()
            .flat_map(|connection| {
                let mut vars = Vec::new();
                for entity in &[&connection.source, &connection.target] {
                    if entity.id.starts_with('?') && entity.selected_for_projection {
                        let var = entity.id.clone();
                        vars.push(var.clone());
                        if add_service_statement {
                            vars.push(format!("?{}Label", var.trim_start_matches('?')));
                        }
                    }
                }
                for property in &connection.properties {
                    vars.extend(collect_vars_from_property(property, add_service_statement));
                }
                vars
            })
            .collect::<HashSet<_>>();

        let projection_list = if projection_set.is_empty() {
            String::from("*")
        } else {
            let mut sorted_projection_set: Vec<_> = projection_set.into_iter().collect();
            sorted_projection_set.sort(); // Sort the collection
            sorted_projection_set.join(" ")
        };

        let prefix_set = connections
            .iter()
            .flat_map(|connection| {
                let mut prefixes = Vec::new();
                for entity in &[&connection.source, &connection.target] {
                    if !entity.prefix.iri.is_empty() {
                        prefixes.push(entity.prefix.clone());
                    }
                }
                for property in &connection.properties {
                    prefixes.extend(collect_prefixes_from_property(property));
                }
                prefixes
            })
            .collect::<HashSet<_>>();

        let prefix_list = if prefix_set.is_empty() {
            String::from("")
        } else {
            let mut temp = prefix_set
                .into_iter()
                .map(|prefix| format!("PREFIX {}: <{}>", prefix.abbreviation, prefix.iri))
                .collect::<Vec<_>>();
            temp.sort();
            format!("{}\n\n", temp.join("\n"))
        };

        let where_clause: String = connections
            .iter()
            .map(|connection| {
                let source_iri = get_iri(&connection.source.id, &connection.source.prefix);
                let target_iri = get_iri(&connection.target.id, &connection.target.prefix);

                connection.properties.iter().map(|property| {
                    let property_path = generate_property_path(property);
                    format!(
                        "{}{} {} {} .\n{}# {} -- [{}] -> {}\n",
                        indentation,
                        source_iri,
                        property_path,
                        target_iri,
                        indentation,
                        connection.source.label,
                        property.label,
                        connection.target.label
                    )
                }).collect::<Vec<String>>().join("")
            })
            .collect();

        let service = if add_service_statement {
            format!(
                "{}SERVICE wikibase:label {{ bd:serviceParam wikibase:language \"[AUTO_LANGUAGE],en\". }}\n",
                indentation
            )
        } else {
            String::from("")
        };

        if add_label_service_prefixes {
            format!(
                "{}\n{}\n{}SELECT {} WHERE {{\n{}{}}}",
                BD_PREFIX, WIKIBASE_PREFIX, prefix_list, projection_list, where_clause, service
            )
        } else {
            format!(
                "{}SELECT {} WHERE {{\n{}{}}}",
                prefix_list, projection_list, where_clause, service
            )
        }
    }
}

fn parse_query(query: &str) -> Result<Query, SparqlSyntaxError> {
    Query::parse(query, None)
}

fn bgp_to_vqg(bgp: Vec<TriplePattern>) -> Vec<Connection> {
    bgp.iter()
        .map(|pattern| {
            connection_constructor(
                pattern.subject.to_string(),
                pattern.predicate.to_string(),
                pattern.object.to_string(),
            )
        })
        .collect()
}

#[wasm_bindgen]
pub fn query_to_vqg_wasm(query: &str) -> String {
    // for better errors logging in the web browser
    set_panic_hook();

    to_string(&query_to_vqg(query)).unwrap()
}

/// We get a query, can be a SELECT query or something else.
/// A SELECT statement consist of a:
/// - dataset
/// - graph pattern
/// - base IRI (optional)
///
/// The "graph pattern" is equivalent to a SPARQL Basic Graph Pattern (BGP)
fn query_to_vqg(query: &str) -> Vec<Connection> {

    if query.is_empty() {
        return vec![];
    }

    fn _helper(parsed_query: Result<Query, SparqlSyntaxError>) -> Vec<Connection> {
        // Match on the query type.
        match parsed_query {
            Ok(Query::Select { pattern: p, .. }) => match p {
                GraphPattern::Project {
                    variables: v,
                    inner: i,
                } => {
                    // Extract projection variable names
                    let projection_vars: HashSet<String> = v
                        .iter()
                        .map(|var| format!("?{}", var.as_str()))
                        .collect();

                    let mut connections = match_bgp_or_path_to_vqg(*i);

                    // Mark entities based on whether they're in the projection
                    for connection in &mut connections {
                        if connection.source.id.starts_with('?') {
                            connection.source.selected_for_projection =
                                projection_vars.contains(&connection.source.id);
                        }
                        if connection.target.id.starts_with('?') {
                            connection.target.selected_for_projection =
                                projection_vars.contains(&connection.target.id);
                        }
                        for property in &mut connection.properties {
                            if property.id.starts_with('?') {
                                property.selected_for_projection =
                                    projection_vars.contains(&property.id);
                            }
                        }
                    }

                    connections
                },
                _ => match_bgp_or_path_to_vqg(p),
            },
            _ => vec![],
        }
    }
    let parsed_query = parse_query(query);
    match parsed_query {
        Err(_error) => {
            let new_query = format!("{}{}{}", WIKIBASE_PREFIX, BD_PREFIX, query);
            query_to_vqg(&new_query)
        }
        _ => _helper(parsed_query),
    }
}

/// This will only match a subclass of [SPARQL queries](https://www.w3.org/TR/sparql11-query/).
///
/// ```sparql
///  PREFIX bd: <http://www.bigdata.com/rdf#>
//   PREFIX wikibase: <http://wikiba.se/ontology#>
//   PREFIX wd: <http://www.wikidata.org/entity/>
//   SELECT ?3 ?3Label WHERE {
//     wd:Q5879 ?3 wd:Q2079 .
//     # Johann Wolfgang von Goethe -- [Variable] -> Leipzig
//     SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en". }
//   }
/// ```
fn match_bgp_or_path_to_vqg(p: GraphPattern) -> Vec<Connection> {
    match p {
        GraphPattern::Bgp { patterns: bgp } => bgp_to_vqg(bgp),
        // ignore any service statements
        GraphPattern::Service {
            name: _n,
            inner: _i,
            silent: _s,
        } => vec![],
        // this will match e.g. a BGP and a SERVICE statement
        GraphPattern::Join { left: l, right: r } => {
            let l_parsed = match_bgp_or_path_to_vqg(*l);
            let r_parsed = match_bgp_or_path_to_vqg(*r);
            l_parsed.into_iter().chain(r_parsed).collect()
        }
        GraphPattern::Path {
            subject: s,
            path: p,
            object: o,
        } => {
            let connection = connection_constructor(
                s.to_string(),
                p.to_string(), // Default string representation for property
                o.to_string(),
            );
            // todo: use spargebra::algebra::PropertyPath, to decompose it here.
            vec![connection]
        }
        _ => vec![],
    }
}

fn connection_constructor(
    subject_name: String,
    predicate_name: String,
    object_name: String,
) -> Connection {
    Connection {
        source: Entity {
            id: subject_name.clone(),
            label: subject_name.clone(),
            prefix: Prefix {
                iri: "".to_string(),
                abbreviation: "".to_string(),
            },
            selected_for_projection: true, // Default to true
        },
        target: Entity {
            id: object_name.clone(),
            label: object_name.clone(),
            prefix: Prefix {
                iri: "".to_string(),
                abbreviation: "".to_string(),
            },
            selected_for_projection: true, // Default to true
        },
        properties: vec![Property {
            id: predicate_name.clone(),
            label: predicate_name.clone(),
            prefix: Prefix {
                iri: "".to_string(),
                abbreviation: "".to_string(),
            },
            selected_for_projection: true, // Default to true
            properties: vec![],
            path_type: None,
            modifier: None,
        }],
    }
}
