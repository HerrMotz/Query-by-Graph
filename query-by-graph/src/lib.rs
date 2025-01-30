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

#[derive(Serialize, Deserialize)]
pub struct Entity {
    pub id: String,
    pub label: String,
    pub prefix: Prefix,
}

#[derive(Serialize, Deserialize, Clone, Eq, Hash, PartialEq)]
pub struct Prefix {
    iri: String,
    abbreviation: String,
}

#[derive(Serialize, Deserialize)]
pub struct Connection {
    pub property: Entity,
    pub source: Entity,
    pub target: Entity,
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

fn vqg_to_query(connections: Vec<Connection>, add_service_statement: bool, add_label_service_prefixes: bool) -> String {
    let indentation = " ".repeat(INDENTATION_COUNT);

    if connections.len() < 1 {
        String::from("")
    } else {
        let projection_set = connections
            .iter()
            .flat_map(|connection| {
                vec![&connection.source, &connection.target, &connection.property]
            })
            .filter(|entity| entity.id.starts_with('?'))
            .flat_map(|entity| {
                let var = entity.id.clone();
                if add_service_statement {
                    let label_var = format!("?{}Label", var.trim_start_matches("?"));
                    vec![var, label_var]
                } else {
                    vec![var]
                }
            })
            .collect::<HashSet<_>>();

        let projection_list = if projection_set.len() == 0 {
            String::from("*")
        } else {
            let mut sorted_projection_set: Vec<_> = projection_set.into_iter().collect();
            sorted_projection_set.sort(); // Sort the collection
            sorted_projection_set.join(" ")
        };

        let prefix_set = connections
            .iter()
            .flat_map(|connection| {
                vec![&connection.source, &connection.target, &connection.property]
            })
            .filter(|entity| !entity.prefix.iri.is_empty())
            .map(|entity| entity.prefix.clone())
            .collect::<HashSet<_>>();

        let prefix_list = if prefix_set.len() == 0 {
            String::from("")
        } else {
            let mut temp = prefix_set
                .into_iter()
                // e.g. PREFIX wd: <http://www.wikidata.org/entity/>
                .map(|prefix| format!("PREFIX {}: <{}>", prefix.abbreviation, prefix.iri))
                .collect::<Vec<_>>();
            temp.sort();
            format!("{}\n\n", temp.join("\n"))
        };

        let where_clause: String = connections
            .iter()
            .map(|connection| {
                let source_iri = if connection.source.prefix.iri.is_empty() {
                    connection.source.id.clone() // Clone the String to avoid moving it
                } else {
                    format!(
                        "{}:{}",
                        connection.source.prefix.abbreviation, connection.source.id
                    )
                };

                let property_iri = if connection.property.prefix.iri.is_empty() {
                    connection.property.id.clone() // Clone the String to avoid moving it
                } else {
                    format!(
                        "{}:{}",
                        connection.property.prefix.abbreviation, connection.property.id
                    )
                };

                let target_iri = if connection.target.prefix.iri.is_empty() {
                    connection.target.id.clone() // Clone the String to avoid moving it
                } else {
                    format!(
                        "{}:{}",
                        connection.target.prefix.abbreviation, connection.target.id
                    )
                };

                format!(
                    "{}{} {} {} .\n{}# {} -- [{}] -> {}\n",
                    indentation,
                    source_iri,
                    property_iri,
                    target_iri,
                    indentation,
                    connection.source.label,
                    connection.property.label,
                    connection.target.label
                )
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
    fn _helper(parsed_query: Result<Query, SparqlSyntaxError>) -> Vec<Connection> {
        // Match on the query type.
        match parsed_query {
            Ok(Query::Select { pattern: p, .. }) => match p {
                GraphPattern::Project {
                    variables: _,
                    inner: i,
                } => match i {
                    _ => match_bgp_or_path_to_vqg(*i),
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
        } => vec![connection_constructor(
            s.to_string(),
            p.to_string(),
            o.to_string(),
        )],
        _ => vec![],
    }
}

fn connection_constructor(
    subject_name: String,
    predicate_name: String,
    object_name: String,
) -> Connection {
    Connection {
        property: Entity {
            id: predicate_name.clone(),
            label: predicate_name.clone(),
            prefix: Prefix {
                iri: "".to_string(),
                abbreviation: "".to_string(),
            },
        },
        source: Entity {
            id: subject_name.clone(),
            label: subject_name.clone(),
            prefix: Prefix {
                iri: "".to_string(),
                abbreviation: "".to_string(),
            },
        },
        target: Entity {
            id: object_name.clone(),
            label: object_name.clone(),
            prefix: Prefix {
                iri: "".to_string(),
                abbreviation: "".to_string(),
            },
        },
    }
}
