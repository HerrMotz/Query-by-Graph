mod utils;

use crate::utils::set_panic_hook;
use serde::{Deserialize, Serialize};
use serde_json::{from_str, to_string};
use spargebra::algebra::{GraphPattern, PropertyPathExpression};
use spargebra::term::{TriplePattern, TermPattern, NamedNodePattern};
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
    #[serde(default)]
    pub distinct: bool,
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

    let connections: Vec<Connection> = from_str(json).unwrap_or_else(|_| vec![]);
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

    if property.properties.is_empty() {
        if let Some(m) = &property.modifier {
            format!("{}{}", iri, m)
        } else {
            iri
        }
    } else {
        let parts: Vec<String> = property
            .properties
            .iter()
            .map(|p| generate_property_path(p))
            .collect();
        let separator = match property.path_type.as_deref() {
            Some("alternation") => "|",
            _ => "/",
        };
        let path = parts.join(separator);

        if let Some(m) = &property.modifier {
            format!("({}){}", path, m)
        } else {
            format!("({})", path)
        }
    }
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
        fn collect_vars(id: &str, selected: bool, add_service_statement: bool) -> Vec<String> {
            let mut vars = Vec::new();
            if id.starts_with('?') && selected {
                let var = id.to_string();
                vars.push(var.clone());
                if add_service_statement {
                    vars.push(format!("?{}Label", var.trim_start_matches('?')));
                }
            }
            vars
        }

        fn collect_vars_from_property(property: &Property, add_service_statement: bool) -> Vec<String> {
            let mut vars = collect_vars(&property.id, property.selected_for_projection, add_service_statement);
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
                    vars.extend(collect_vars(&entity.id, entity.selected_for_projection, add_service_statement));
                }
                for property in &connection.properties {
                    vars.extend(collect_vars_from_property(property, add_service_statement));
                }
                vars
            })
            .collect::<HashSet<_>>();

        let has_distinct = connections.iter().any(|connection| {
            (connection.source.id.starts_with('?') && connection.source.selected_for_projection && connection.source.distinct)
                || (connection.target.id.starts_with('?') && connection.target.selected_for_projection && connection.target.distinct)
        });

        let projection_list = if projection_set.is_empty() {
            String::from("*")
        } else {
            let mut sorted_projection_set: Vec<_> = projection_set.into_iter().collect();
            sorted_projection_set.sort(); // Sort the collection
            sorted_projection_set.join(" ")
        };

        let distinct_keyword = if has_distinct { "DISTINCT " } else { "" };

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

        // Detect whether any entity uses an ^^xsd: typed literal and inject the XSD prefix if so.
        let uses_xsd = connections.iter().any(|c| {
            c.source.id.contains("^^xsd:")
                || c.target.id.contains("^^xsd:")
                || c.properties.iter().any(|p| p.id.contains("^^xsd:"))
        });
        let xsd_prefix = if uses_xsd {
            "PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>\n\n"
        } else {
            ""
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
                "{}\n{}\n{}{}SELECT {}{} WHERE {{\n{}{}}}",
                BD_PREFIX, WIKIBASE_PREFIX, xsd_prefix, prefix_list, distinct_keyword, projection_list, where_clause, service
            )
        } else {
            format!(
                "{}{}SELECT {}{} WHERE {{\n{}{}}}",
                xsd_prefix, prefix_list, distinct_keyword, projection_list, where_clause, service
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
                term_pattern_to_string(&pattern.subject),
                named_node_pattern_to_string(&pattern.predicate),
                term_pattern_to_string(&pattern.object),
            )
        })
        .collect()
}

fn term_pattern_to_string(tp: &TermPattern) -> String {
    match tp {
        TermPattern::NamedNode(n) => n.to_string(),
        TermPattern::BlankNode(b) => b.to_string(),
        TermPattern::Literal(l) => l.to_string(),
        TermPattern::Variable(v) => format!("?{}", v.as_str()),
    }
}

fn named_node_pattern_to_string(nnp: &NamedNodePattern) -> String {
    match nnp {
        NamedNodePattern::NamedNode(n) => n.to_string(),
        NamedNodePattern::Variable(v) => format!("?{}", v.as_str()),
    }
}

fn property_path_to_property(path: &PropertyPathExpression) -> Property {
    match path {
        PropertyPathExpression::NamedNode(n) => Property {
            id: n.to_string(),
            label: n.to_string(),
            prefix: Prefix {
                iri: "".to_string(),
                abbreviation: "".to_string(),
            },
            selected_for_projection: true,
            properties: vec![],
            path_type: None,
            modifier: None,
        },
        PropertyPathExpression::Reverse(inner) => {
            let mut p = property_path_to_property(inner);
            p.modifier = Some("^".to_string());
            p
        }
        PropertyPathExpression::Sequence(left, right) => Property {
            id: "sequence".to_string(),
            label: "sequence".to_string(),
            prefix: Prefix {
                iri: "".to_string(),
                abbreviation: "".to_string(),
            },
            selected_for_projection: true,
            properties: vec![
                property_path_to_property(left),
                property_path_to_property(right),
            ],
            path_type: Some("sequence".to_string()),
            modifier: None,
        },
        PropertyPathExpression::Alternative(left, right) => Property {
            id: "alternation".to_string(),
            label: "alternation".to_string(),
            prefix: Prefix {
                iri: "".to_string(),
                abbreviation: "".to_string(),
            },
            selected_for_projection: true,
            properties: vec![
                property_path_to_property(left),
                property_path_to_property(right),
            ],
            path_type: Some("alternation".to_string()),
            modifier: None,
        },
        PropertyPathExpression::ZeroOrMore(inner) => {
            let mut p = property_path_to_property(inner);
            p.modifier = Some("*".to_string());
            p
        }
        PropertyPathExpression::OneOrMore(inner) => {
            let mut p = property_path_to_property(inner);
            p.modifier = Some("+".to_string());
            p
        }
        PropertyPathExpression::ZeroOrOne(inner) => {
            let mut p = property_path_to_property(inner);
            p.modifier = Some("?".to_string());
            p
        }
        PropertyPathExpression::NegatedPropertySet(nodes) => {
            let label = format!("!({})", nodes.iter().map(|n| n.to_string()).collect::<Vec<_>>().join("|"));
            Property {
                id: label.clone(),
                label,
                prefix: Prefix {
                    iri: "".to_string(),
                    abbreviation: "".to_string(),
                },
                selected_for_projection: true,
                properties: vec![],
                path_type: None,
                modifier: None,
            }
        }
    }
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
            Ok(Query::Select { pattern: p, .. }) => {
                let (connections, projection_vars, is_distinct) = match p {
                    GraphPattern::Distinct { inner } => match *inner {
                        GraphPattern::Project { variables: v, inner: i } => (
                            match_bgp_or_path_to_vqg(*i),
                            Some(v.iter().map(|var| format!("?{}", var.as_str())).collect::<HashSet<String>>()),
                            true,
                        ),
                        other => (match_bgp_or_path_to_vqg(other), None, true),
                    },
                    GraphPattern::Project {
                        variables: v,
                        inner: i,
                    } => (
                        match_bgp_or_path_to_vqg(*i),
                        Some(v.iter().map(|var| format!("?{}", var.as_str())).collect::<HashSet<String>>()),
                        false,
                    ),
                    _ => (match_bgp_or_path_to_vqg(p), None, false),
                };

                let mut connections = connections;
                // Mark entities based on whether they're in the projection
                if let Some(vars) = projection_vars {
                    for connection in &mut connections {
                        if connection.source.id.starts_with('?') {
                            connection.source.selected_for_projection =
                                vars.contains(&connection.source.id);
                            connection.source.distinct =
                                is_distinct && vars.contains(&connection.source.id);
                        }
                        if connection.target.id.starts_with('?') {
                            connection.target.selected_for_projection =
                                vars.contains(&connection.target.id);
                            connection.target.distinct =
                                is_distinct && vars.contains(&connection.target.id);
                        }
                        for property in &mut connection.properties {
                            if property.id.starts_with('?') {
                                property.selected_for_projection =
                                    vars.contains(&property.id);
                            }
                        }
                    }
                }
                connections
            },
            _ => vec![],
        }
    }
    let parsed_query = parse_query(query);
    match parsed_query {
        Err(_error) if !query.starts_with(WIKIBASE_PREFIX) && !query.starts_with(BD_PREFIX) => {
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
        GraphPattern::Distinct { inner } => match_bgp_or_path_to_vqg(*inner),
        GraphPattern::Path {
            subject: s,
            path: p,
            object: o,
        } => {
            let mut connection = connection_constructor(
                term_pattern_to_string(&s),
                "".to_string(),
                term_pattern_to_string(&o),
            );
            connection.properties = vec![property_path_to_property(&p)];
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
            distinct: false,
        },
        target: Entity {
            id: object_name.clone(),
            label: object_name.clone(),
            prefix: Prefix {
                iri: "".to_string(),
                abbreviation: "".to_string(),
            },
            selected_for_projection: true, // Default to true
            distinct: false,
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
