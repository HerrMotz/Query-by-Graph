use query_by_graph::{query_to_vqg_wasm, vqg_to_query_wasm};
use spargebra::Query;

#[test]
fn zebratlas_example_round_trips_without_wikibase_services() {
    let example = include_str!("../../docs/examples/zebratlas.rq");
    let graph = query_to_vqg_wasm(example);
    let connections: serde_json::Value = serde_json::from_str(&graph).unwrap();
    assert_eq!(connections.as_array().unwrap().len(), 3);
    let query = vqg_to_query_wasm(&graph, false, false);
    Query::parse(&query, None).expect("Generated query must be valid SPARQL");
    assert!(query.contains("https://w3id.org/rare-disease-atlas/id/HGNC%3A11444"));
    assert!(query.contains("https://w3id.org/rare-disease-atlas/vocab#has_associated_gene"));
    assert!(query.contains("http://purl.org/dc/terms/source"));
    assert!(!query.contains("wikibase:label"));
    assert!(!query.contains("SERVICE"));
    let rebuilt: serde_json::Value = serde_json::from_str(&query_to_vqg_wasm(&query)).unwrap();
    assert_eq!(rebuilt.as_array().unwrap().len(), 3);
}
