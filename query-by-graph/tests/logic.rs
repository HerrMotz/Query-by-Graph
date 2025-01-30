//! Test suite for the backend logic
use serde_json::to_string;
use query_by_graph::{vqg_to_query_wasm, query_to_vqg_wasm};
use spargebra::{Query};

#[test]
fn test_empty_query() {
    assert_eq!(vqg_to_query_wasm("[]", false, false), "");
}

#[test]
fn test_reversibility_of_parse_query() {
    let query = r###"PREFIX wd: <http://www.wikidata.org/entity/>
SELECT ?relation WHERE {
     wd:Q5879 ?relation wd:Q154804 .
    # Johann Wolfgang von Goethe -- [Variable] -> Leipzig University
}"###;
    let result = Query::parse(query, None).unwrap();

    assert_eq!(result.to_string(), query)
}

#[test]
fn test_reversibility_of_parse_with_service_statements_for_labels() {
    let query2 = r###"
PREFIX bd: <http://www.bigdata.com/rdf#>
PREFIX wikibase: <http://wikiba.se/ontology#>
PREFIX wd: <http://www.wikidata.org/entity/>
SELECT ?3 ?3Label WHERE {
     wd:Q5879 ?3 wd:Q2079 .
    # Johann Wolfgang von Goethe -- [Variable] -> Leipzig
    SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en". }
}
"###;
    let expected2 = "[{\"property\":{\"id\":\"?3\",\"label\":\"?3\",\"prefix\":{\"iri\":\"\",\"abbreviation\":\"\"}},\"source\":{\"id\":\"<http://www.wikidata.org/entity/Q5879>\",\"label\":\"<http://www.wikidata.org/entity/Q5879>\",\"prefix\":{\"iri\":\"\",\"abbreviation\":\"\"}},\"target\":{\"id\":\"<http://www.wikidata.org/entity/Q2079>\",\"label\":\"<http://www.wikidata.org/entity/Q2079>\",\"prefix\":{\"iri\":\"\",\"abbreviation\":\"\"}}}]";
    let result = query_to_vqg_wasm(query2);
    assert_eq!(expected2, result)
}

#[test]
fn serialize_graph() {
    let graph = query_to_vqg_wasm("SELECT ?3 WHERE { <http://www.wikidata.org/entity/Q5879> ?3 <http://www.wikidata.org/entity/Q152838> .}");
    print!("{:?}", to_string(&graph).unwrap());
    assert_eq!(graph, "")
}


#[test]
fn test_simple_query() {
    let query = r###"[{"property":{"id":"?variable1","label":"Variable","description":"Variable Entity","prefix":{"iri":"","abbreviation":""},"dataSource":{"name":"","url":"","preferredLanguages":[],"propertyPrefix":{"url":"","abbreviation":""},"entityPrefix":{"url":"","abbreviation":""},"queryService":""}},"source":{"id":"Q5879","label":"Johann Wolfgang von Goethe","description":"German writer, artist, natural scientist and politician (1749–1832)","prefix":{"iri":"http://www.wikidata.org/entity/","abbreviation":"wd"},"dataSource":{"name":"WikiData","url":"https://www.wikidata.org/w/api.php","preferredLanguages":["en"],"entityPrefix":{"url":"http://www.wikidata.org/entity/","abbreviation":"wd"},"propertyPrefix":{"url":"http://www.wikidata.org/prop/direct/","abbreviation":"wdt"},"queryService":"https://query.wikidata.org/ "}},"target":{"id":"Q154804","label":"Leipzig University","description":"university in Leipzig, Saxony, Germany (1409-)","prefix":{"iri":"http://www.wikidata.org/entity/","abbreviation":"wd"},"dataSource":{"name":"WikiData","url":"https://www.wikidata.org/w/api.php","preferredLanguages":["en"],"entityPrefix":{"url":"http://www.wikidata.org/entity/","abbreviation":"wd"},"propertyPrefix":{"url":"http://www.wikidata.org/prop/direct/","abbreviation":"wdt"},"queryService":"https://query.wikidata.org/ "}}}]"###;
    assert_eq!(vqg_to_query_wasm(query, false, false), "PREFIX wd: <http://www.wikidata.org/entity/>
SELECT ?variable1 WHERE {
     wd:Q5879 ?variable1 wd:Q154804 .
    # Johann Wolfgang von Goethe -- [Variable] -> Leipzig University
}")
}
