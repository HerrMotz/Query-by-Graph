use query_by_graph::{query_to_vqg_wasm, vqg_to_query_wasm};
use serde_json::json;

#[test]
fn test_alternation_path() {
    let query = "PREFIX ex: <http://example.org/> SELECT * WHERE { ?x (ex:type1|ex:type2)+ ex:TargetClass . }";
    let json = query_to_vqg_wasm(query);
    println!("JSON: {}", json);
}

#[test]
fn test_structured_sequence_to_query() {
    let connections = json!([
        {
            "source": { "id": "?item", "label": "item", "prefix": { "iri": "", "abbreviation": "" } },
            "target": { "id": "wd:Q5", "label": "Human", "prefix": { "iri": "http://www.wikidata.org/entity/", "abbreviation": "wd" } },
            "properties": [
                {
                    "id": "root",
                    "label": "path",
                    "prefix": { "iri": "", "abbreviation": "" },
                    "pathType": "sequence",
                    "properties": [
                        { "id": "P31", "label": "instance of", "prefix": { "iri": "http://www.wikidata.org/prop/direct/", "abbreviation": "wdt" } },
                        { "id": "P279", "label": "subclass of", "prefix": { "iri": "http://www.wikidata.org/prop/direct/", "abbreviation": "wdt" }, "modifier": "*" }
                    ]
                }
            ]
        }
    ]);
    
    let query = vqg_to_query_wasm(&connections.to_string(), false, false);
    println!("Query:\n{}", query);
    assert!(query.contains("wdt:P31/(wdt:P279*)"));
}

#[test]
fn test_structured_alternation_to_query() {
    let connections = json!([
        {
            "source": { "id": "?x", "label": "x", "prefix": { "iri": "", "abbreviation": "" } },
            "target": { "id": "ex:Target", "label": "Target", "prefix": { "iri": "http://example.org/", "abbreviation": "ex" } },
            "properties": [
                {
                    "id": "root",
                    "label": "path",
                    "prefix": { "iri": "", "abbreviation": "" },
                    "pathType": "alternation",
                    "modifier": "+",
                    "properties": [
                        { "id": "type", "label": "type", "prefix": { "iri": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "abbreviation": "rdf" } },
                        { "id": "subClassOf", "label": "subclass", "prefix": { "iri": "http://www.w3.org/2000/01/rdf-schema#", "abbreviation": "rdfs" } }
                    ]
                }
            ]
        }
    ]);
    
    let query = vqg_to_query_wasm(&connections.to_string(), false, false);
    println!("Query:\n{}", query);
    assert!(query.contains("(rdf:type|rdfs:subClassOf)+"));
}
