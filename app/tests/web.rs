//! Test suite for the Web and headless browsers.
//!
//! These are smoke tests for the `#[wasm_bindgen]` boundary itself — the
//! conversion logic is covered in depth by the native tests (`logic.rs`,
//! `resilience.rs`, `property_paths.rs`). Run with `npm run test-rs`.

#![cfg(target_arch = "wasm32")]

extern crate wasm_bindgen_test;

use query_by_graph::query_to_vqg_wasm;
use query_by_graph::vqg_to_query_wasm;
use wasm_bindgen_test::*;

wasm_bindgen_test_configure!(run_in_browser);

const GOETHE_GRAPH: &str = r###"[{
    "source": {
        "id": "Q5879",
        "label": "Johann Wolfgang von Goethe",
        "prefix": {"iri": "http://www.wikidata.org/entity/", "abbreviation": "wd"}
    },
    "target": {
        "id": "Q154804",
        "label": "Leipzig University",
        "prefix": {"iri": "http://www.wikidata.org/entity/", "abbreviation": "wd"}
    },
    "properties": [{
        "id": "?relation",
        "label": "Variable",
        "prefix": {"iri": "", "abbreviation": ""}
    }]
}]"###;

const GOETHE_QUERY: &str = r###"PREFIX wd: <http://www.wikidata.org/entity/>
SELECT ?relation WHERE {
     wd:Q5879 ?relation wd:Q154804 .
    # Johann Wolfgang von Goethe -- [Variable] -> Leipzig University
}"###;

#[wasm_bindgen_test]
fn test_empty_graph_yields_empty_query() {
    assert_eq!(vqg_to_query_wasm("[]", false, false), "");
}

#[wasm_bindgen_test]
fn test_graph_to_query() {
    assert_eq!(
        vqg_to_query_wasm(GOETHE_GRAPH, false, false),
        "PREFIX wd: <http://www.wikidata.org/entity/>\n\nSELECT ?relation WHERE {\n    wd:Q5879 ?relation wd:Q154804 .\n    # Johann Wolfgang von Goethe -- [Variable] -> Leipzig University\n}"
    );
}

#[wasm_bindgen_test]
fn test_query_to_graph() {
    let graph = query_to_vqg_wasm(GOETHE_QUERY);

    // The parser resolves prefixes to full IRIs, so the entities come back
    // expanded; the variable predicate survives verbatim.
    assert!(graph.contains(r#""id":"?relation""#), "graph was: {}", graph);
    assert!(
        graph.contains("http://www.wikidata.org/entity/Q5879"),
        "graph was: {}",
        graph
    );
    assert!(
        graph.contains("http://www.wikidata.org/entity/Q154804"),
        "graph was: {}",
        graph
    );
}

#[wasm_bindgen_test]
fn test_unparseable_query_does_not_panic() {
    // `query_to_vqg_wasm` is deliberately lossy-tolerant: bad input must return
    // an empty graph rather than trapping the wasm module.
    assert_eq!(query_to_vqg_wasm("this is not a SPARQL query"), "[]");
}
