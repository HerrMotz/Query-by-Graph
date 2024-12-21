mod utils;

use std::collections::HashSet;
use wasm_bindgen::prelude::*;
use serde_json::from_str;
use serde::Deserialize;
use crate::utils::set_panic_hook;

const INDENTATION_COUNT:usize = 4;

#[derive(Deserialize)]
struct Entity {
    pub id: String,
    pub label: String,
    pub prefix: Prefix
}

#[derive(Deserialize, Clone, Eq, Hash, PartialEq)]
struct Prefix {
    uri: String,
    abbreviation: String
}

#[derive(Deserialize)]
struct Connection {
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
    let projection_set = connections.iter()
                                 .flat_map(|connection| {
                                     vec![&connection.source, &connection.target, &connection.property]
                                 })
                                 .filter(|entity| entity.id.starts_with('?'))
                                 .flat_map(|entity| {
                                    let var = entity.id.clone();
                                    let label_var = format!("?{}Label", var.trim_start_matches("?"));
                                    vec![var, label_var]
                                })
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
        .filter(|entity| !entity.prefix.uri.is_empty())
        .map(|entity| entity.prefix.clone())
        .collect::<HashSet<_>>();

    let prefix_list = if prefix_set.len() == 0 { String::from("") } else {
        prefix_set.into_iter()
        // PREFIX wd: <http://www.wikidata.org/entity/>
        .map(|prefix| format!("PREFIX {}: <{}>", prefix.abbreviation, prefix.uri))
        .collect::<Vec<_>>()
        .join("\n")
    };

    let where_clause: String = connections.iter()
        .map(|connection| {
            let source_uri = if connection.source.prefix.uri.is_empty() {
                connection.source.id.clone() // Clone the String to avoid moving it
            } else {
                format!("{}:{}", connection.source.prefix.abbreviation, connection.source.id)
            };

            let property_uri = if connection.property.prefix.uri.is_empty() {
                connection.property.id.clone() // Clone the String to avoid moving it
            } else {
                format!("{}:{}", connection.property.prefix.abbreviation, connection.property.id)
            };

            let target_uri = if connection.target.prefix.uri.is_empty() {
                connection.target.id.clone() // Clone the String to avoid moving it
            } else {
                format!("{}:{}", connection.target.prefix.abbreviation, connection.target.id)
            };


            let indentation = " ".repeat(INDENTATION_COUNT);

            format!(
                "{} {} {} {} . \n{}# {} -- [{}] -> {}\n",
                indentation,
                source_uri,
                property_uri,
                target_uri,
                indentation,
                connection.source.label,
                connection.property.label,
                connection.target.label
            )
        })
        .collect();

        let indentation = " ".repeat(INDENTATION_COUNT);
        let service = format!(
            "{}SERVICE wikibase:label {{ bd:serviceParam wikibase:language \"[AUTO_LANGUAGE],en\". }}",
            indentation
        );

    format!(
        "{}\nSELECT {} WHERE {{\n{}{}\n}}",
        prefix_list, projection_list, where_clause, service
    )
}
