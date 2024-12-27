mod utils;

use std::collections::HashSet;
use wasm_bindgen::prelude::*;
use serde_json::{from_str, to_string};
use serde::{Deserialize, Serialize};
use crate::utils::set_panic_hook;
use spargebra::{Query, SparqlSyntaxError};
use spargebra::algebra::GraphPattern;
use spargebra::term::{TriplePattern};

const INDENTATION_COUNT:usize = 4;

#[derive(Serialize, Deserialize)]
pub struct Entity {
    pub id: String,
    pub label: String,
    pub prefix: Prefix
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
pub fn graph_to_query_wasm(json: &str) -> String {
    // for better errors logging in the web browser
    set_panic_hook();

    let connections: Vec<Connection> = from_str(json).unwrap();
    graph_to_query(connections)
}

fn graph_to_query(connections: Vec<Connection>) -> String {
    if connections.len() < 1 {
        String::from("")
    } else {
        let projection_set = connections.iter()
            .flat_map(|connection| {
                vec![&connection.source, &connection.target, &connection.property]
            })
            .filter(|entity| entity.id.starts_with('?'))
            .map(|entity| entity.id.clone())
            .collect::<HashSet<_>>();

        let projection_list = if projection_set.len() == 0 {
            String::from("*")
        } else {
            let mut sorted_projection_set: Vec<_> = projection_set.into_iter().collect();
            sorted_projection_set.sort(); // Sort the collection
            sorted_projection_set.join(" ")
        };

        let prefix_set = connections.iter()
            .flat_map(|connection| {
                vec![&connection.source, &connection.target, &connection.property]
            })
            .filter(|entity| !entity.prefix.iri.is_empty())
            .map(|entity| entity.prefix.clone())
            .collect::<HashSet<_>>();

        let prefix_list = if prefix_set.len() == 0 { String::from("") } else {
            let mut temp = prefix_set.into_iter()
                // PREFIX wd: <http://www.wikidata.org/entity/>
                .map(|prefix| format!("PREFIX {}: <{}>", prefix.abbreviation, prefix.iri))
                .collect::<Vec<_>>();
            temp.sort();
            temp.join("\n")
        };

        let where_clause: String = connections.iter()
            .map(|connection| {
                let source_iri = if connection.source.prefix.iri.is_empty() {
                    connection.source.id.clone() // Clone the String to avoid moving it
                } else {
                    format!("{}:{}", connection.source.prefix.abbreviation, connection.source.id)
                };

                let property_iri = if connection.property.prefix.iri.is_empty() {
                    connection.property.id.clone() // Clone the String to avoid moving it
                } else {
                    format!("{}:{}", connection.property.prefix.abbreviation, connection.property.id)
                };

                let target_iri = if connection.target.prefix.iri.is_empty() {
                    connection.target.id.clone() // Clone the String to avoid moving it
                } else {
                    format!("{}:{}", connection.target.prefix.abbreviation, connection.target.id)
                };


                let indentation = " ".repeat(INDENTATION_COUNT);

                format!(
                    "{} {} {} {} .\n{}# {} -- [{}] -> {}\n",
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

        format!(
            "{}\nSELECT {} WHERE {{\n{}}}",
            prefix_list, projection_list, where_clause
        )
    }
}

fn parse_query(query: &str) -> Result<Query, SparqlSyntaxError> {
    Query::parse(query, None)
}

fn bgp_to_graph(bgp: Vec<TriplePattern>) -> Vec<Connection> {
    bgp.iter().map(
        |pattern| {
            connection_constructor(
                pattern.subject.to_string(), 
                pattern.predicate.to_string(), 
                pattern.object.to_string()
            )
        }
    ).collect()
}

#[wasm_bindgen]
pub fn query_to_graph_wasm(query: &str) -> String {
    // for better errors logging in the web browser
    set_panic_hook();

    to_string(&query_to_graph(query)).unwrap()
}

/// We get a query, can be a SELECT query or something else.
/// A SELECT statement consist of a:
/// - dataset
/// - graph pattern
/// - base IRI (optional)
///
/// The "graph pattern" is equivalent to a SPARQL Basic Graph Pattern (BGP)
fn query_to_graph(query: &str) -> Vec<Connection> {
    let parsed_query = parse_query(query);

    // Match on the query type.
    match parsed_query {
        Ok(Query::Select { pattern: p, .. }) => match p {
            GraphPattern::Project {variables: _, inner: i} => match i {
                _ => match_bgp_or_path_to_graph(*i)
            }
            _ => match_bgp_or_path_to_graph(p)
        },
        _ => vec![],
    }
}

fn match_bgp_or_path_to_graph(p: GraphPattern) -> Vec<Connection> {
    match p {
        GraphPattern::Bgp { patterns: bgp } => bgp_to_graph(bgp),
        GraphPattern::Path {
            subject: s,
            path: p,
            object: o
        } => vec![connection_constructor(s.to_string(), p.to_string(), o.to_string())],
        _ => vec![]
    }
}

fn connection_constructor(subject_name: String, predicate_name: String, object_name: String) -> Connection {
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