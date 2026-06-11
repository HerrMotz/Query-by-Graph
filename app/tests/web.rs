//! Test suite for the Web and headless browsers.

#![cfg(target_arch = "wasm32")]

extern crate wasm_bindgen_test;
use std::print;

use wasm_bindgen_test::*;
use serde_json::to_string;
use query_by_graph::vqg_to_query_wasm;
use query_by_graph::query_to_vqg_wasm;

wasm_bindgen_test_configure!(run_in_browser);

#[wasm_bindgen_test]
fn test_empty_query() {
    assert_eq!(vqg_to_query_wasm("[]"), "");
}

#[wasm_bindgen_test]
fn graph_to_query_works() {
    let result = query_to_vqg_wasm(r###"PREFIX wd: <http://www.wikidata.org/entity/>
SELECT ?relation WHERE {
     wd:Q5879 ?relation wd:Q154804 .
    # Johann Wolfgang von Goethe -- [Variable] -> Leipzig University
}"###);
    assert_eq!(result, "")
}

#[wasm_bindgen_test]
fn serialize_graph() {
    let graph = query_to_vqg_wasm("SELECT ?3 WHERE { <http://www.wikidata.org/entity/Q5879> ?3 <http://www.wikidata.org/entity/Q152838> .}");
    print!("{:?}", to_string(&graph).unwrap())
}


#[wasm_bindgen_test]
fn test_simple_query() {
    let query = r###"[{"property":{"id":"?variable1","label":"Variable","description":"Variable Entity","prefix":{"uri":"","abbreviation":""},"dataSource":{"name":"","url":"","preferredLanguages":[],"propertyPrefix":{"url":"","abbreviation":""},"entityPrefix":{"url":"","abbreviation":""},"queryService":""}},"source":{"id":"Q5879","label":"Johann Wolfgang von Goethe","description":"German writer, artist, natural scientist and politician (1749–1832)","prefix":{"uri":"http://www.wikidata.org/entity/","abbreviation":"wd"},"dataSource":{"name":"WikiData","url":"https://www.wikidata.org/w/api.php","preferredLanguages":["en"],"entityPrefix":{"url":"http://www.wikidata.org/entity/","abbreviation":"wd"},"propertyPrefix":{"url":"http://www.wikidata.org/prop/direct/","abbreviation":"wdt"},"queryService":"https://query.wikidata.org/ "}},"target":{"id":"Q154804","label":"Leipzig University","description":"university in Leipzig, Saxony, Germany (1409-)","prefix":{"uri":"http://www.wikidata.org/entity/","abbreviation":"wd"},"dataSource":{"name":"WikiData","url":"https://www.wikidata.org/w/api.php","preferredLanguages":["en"],"entityPrefix":{"url":"http://www.wikidata.org/entity/","abbreviation":"wd"},"propertyPrefix":{"url":"http://www.wikidata.org/prop/direct/","abbreviation":"wdt"},"queryService":"https://query.wikidata.org/ "}}}]"###;
    assert_eq!(vqg_to_query_wasm(query), "PREFIX wd: <http://www.wikidata.org/entity/>
SELECT ?variable1 WHERE {
     wd:Q5879 ?variable1 wd:Q154804 .
    # Johann Wolfgang von Goethe -- [Variable] -> Leipzig University
}")
}
