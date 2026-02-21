use query_by_graph::{query_to_vqg_wasm, vqg_to_query_wasm};
use serde_json::Value;
use spargebra::Query;

fn assert_sparql_equivalent(actual: &str, expected: &str) {
    let actual_parsed = Query::parse(actual, None)
        .unwrap_or_else(|e| panic!("Actual query did not parse:\n{}\nError: {:?}", actual, e));
    let expected_parsed = Query::parse(expected, None)
        .unwrap_or_else(|e| panic!("Expected query did not parse:\n{}\nError: {:?}", expected, e));

    assert_eq!(
        actual_parsed.to_string(),
        expected_parsed.to_string(),
        "SPARQL queries are not equivalent.\nActual:\n{}\nExpected:\n{}",
        actual,
        expected
    );
}

fn select_line(query: &str) -> String {
    query
        .lines()
        .map(str::trim)
        .find(|line| line.starts_with("SELECT "))
        .unwrap_or_else(|| panic!("No SELECT line found in query:\n{}", query))
        .to_string()
}

fn projection_vars(select_line: &str) -> Vec<&str> {
    // "SELECT ?a ?b WHERE {" -> ["?a", "?b"]
    // "SELECT * WHERE {"      -> ["*"]
    let projection_part = select_line
        .trim_start_matches("SELECT ")
        .split(" WHERE")
        .next()
        .unwrap_or("")
        .trim();

    projection_part.split_whitespace().collect()
}

fn parse_connections_json(json: &str) -> Vec<Value> {
    let value: Value =
        serde_json::from_str(json).unwrap_or_else(|e| panic!("Invalid JSON output:\n{}\n{:?}", json, e));

    value
        .as_array()
        .unwrap_or_else(|| panic!("Expected JSON array, got: {}", value))
        .clone()
}

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

    let parsed = Query::parse(query, None).expect("Query should parse");
    let canonical = parsed.to_string();

    // Canonical form should itself be parseable and stable.
    let reparsed = Query::parse(&canonical, None).expect("Canonical query should parse");
    assert_eq!(canonical, reparsed.to_string());

    // Ensure core semantics are preserved.
    assert!(canonical.contains("SELECT ?relation WHERE"));
    assert!(canonical.contains(
        "<http://www.wikidata.org/entity/Q5879> ?relation <http://www.wikidata.org/entity/Q154804>"
    ));
}

#[test]
fn test_reversibility_of_parse_with_service_statements_for_labels() {
    let query = r###"
PREFIX bd: <http://www.bigdata.com/rdf#>
PREFIX wikibase: <http://wikiba.se/ontology#>
PREFIX wd: <http://www.wikidata.org/entity/>
SELECT ?3 ?3Label WHERE {
     wd:Q5879 ?3 wd:Q2079 .
    # Johann Wolfgang von Goethe -- [Variable] -> Leipzig
    SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en". }
}
"###;

    let result = query_to_vqg_wasm(query);
    let connections = parse_connections_json(&result);

    assert_eq!(connections.len(), 1);
    let c = &connections[0];

    assert_eq!(c["properties"][0]["id"], Value::String("?3".to_string()));
    assert_eq!(
        c["source"]["id"],
        Value::String("<http://www.wikidata.org/entity/Q5879>".to_string())
    );
    assert_eq!(
        c["target"]["id"],
        Value::String("<http://www.wikidata.org/entity/Q2079>".to_string())
    );

    // selected_for_projection exists and defaults/sets correctly in current model
    assert_eq!(c["properties"][0]["selectedForProjection"], Value::Bool(true));
    assert_eq!(c["source"]["selectedForProjection"], Value::Bool(true));
    assert_eq!(c["target"]["selectedForProjection"], Value::Bool(true));
}

#[test]
fn serialize_graph() {
    let graph = query_to_vqg_wasm(
        "SELECT ?3 WHERE { <http://www.wikidata.org/entity/Q5879> ?3 <http://www.wikidata.org/entity/Q152838> .}",
    );

    assert!(!graph.is_empty(), "Expected non-empty JSON output");
    let parsed: Value = serde_json::from_str(&graph).expect("Output should be valid JSON");
    let arr = parsed.as_array().expect("Output JSON should be an array");
    assert_eq!(arr.len(), 1, "Expected one connection");
    assert_eq!(arr[0]["properties"][0]["id"], Value::String("?3".to_string()));
}

#[test]
fn test_simple_query() {
    let graph = r###"[{"properties":[{"id":"?variable1","label":"Variable","description":"Variable Entity","prefix":{"iri":"","abbreviation":""},"dataSource":{"name":"","url":"","preferredLanguages":[],"propertyPrefix":{"url":"","abbreviation":""},"entityPrefix":{"url":"","abbreviation":""},"queryService":""}}],"source":{"id":"Q5879","label":"Johann Wolfgang von Goethe","description":"German writer, artist, natural scientist and politician (1749–1832)","prefix":{"iri":"http://www.wikidata.org/entity/","abbreviation":"wd"},"dataSource":{"name":"WikiData","url":"https://www.wikidata.org/w/api.php","preferredLanguages":["en"],"entityPrefix":{"url":"http://www.wikidata.org/entity/","abbreviation":"wd"},"propertyPrefix":{"url":"http://www.wikidata.org/prop/direct/","abbreviation":"wdt"},"queryService":"https://query.wikidata.org/ "}},"target":{"id":"Q154804","label":"Leipzig University","description":"university in Leipzig, Saxony, Germany (1409-)","prefix":{"iri":"http://www.wikidata.org/entity/","abbreviation":"wd"},"dataSource":{"name":"WikiData","url":"https://www.wikidata.org/w/api.php","preferredLanguages":["en"],"entityPrefix":{"url":"http://www.wikidata.org/entity/","abbreviation":"wd"},"propertyPrefix":{"url":"http://www.wikidata.org/prop/direct/","abbreviation":"wdt"},"queryService":"https://query.wikidata.org/ "}}}]"###;

    let result = vqg_to_query_wasm(graph, false, false);

    let expected = r###"PREFIX wd: <http://www.wikidata.org/entity/>
SELECT ?variable1 WHERE {
    wd:Q5879 ?variable1 wd:Q154804 .
}"###;

    assert_sparql_equivalent(&result, expected);
    assert!(
        result.contains("# Johann Wolfgang von Goethe -- [Variable] -> Leipzig University"),
        "Generated query should include comment labels"
    );
}

#[test]
fn test_projection_selection_with_selected_variable() {
    let graph = r###"[{"properties":[{"id":"P69","label":"educated at","prefix":{"iri":"http://www.wikidata.org/prop/direct/","abbreviation":"wdt"},"dataSource":{"name":"WikiData","url":"https://www.wikidata.org/w/api.php","preferredLanguages":["en"],"entityPrefix":{"url":"http://www.wikidata.org/entity/","abbreviation":"wd"},"propertyPrefix":{"url":"http://www.wikidata.org/prop/direct/","abbreviation":"wdt"},"queryService":"https://query.wikidata.org/ "},"selectedForProjection":false}],"source":{"id":"Q5879","label":"Johann Wolfgang von Goethe","prefix":{"iri":"http://www.wikidata.org/entity/","abbreviation":"wd"},"dataSource":{"name":"WikiData","url":"https://www.wikidata.org/w/api.php","preferredLanguages":["en"],"entityPrefix":{"url":"http://www.wikidata.org/entity/","abbreviation":"wd"},"propertyPrefix":{"url":"http://www.wikidata.org/prop/direct/","abbreviation":"wdt"},"queryService":"https://query.wikidata.org/ "},"selectedForProjection":false},"target":{"id":"?university","label":"Variable","prefix":{"iri":"","abbreviation":""},"dataSource":{"name":"","url":"","preferredLanguages":[],"propertyPrefix":{"url":"","abbreviation":""},"entityPrefix":{"url":"","abbreviation":""},"queryService":""},"selectedForProjection":true}}]"###;

    let result = vqg_to_query_wasm(graph, false, false);
    let select = select_line(&result);
    let vars = projection_vars(&select);

    assert_eq!(vars, vec!["?university"]);
    assert!(result.contains("wd:Q5879 wdt:P69 ?university"));
}

#[test]
fn test_projection_selection_with_no_selected_variables() {
    let graph = r###"[{"properties":[{"id":"P69","label":"educated at","prefix":{"iri":"http://www.wikidata.org/prop/direct/","abbreviation":"wdt"},"dataSource":{"name":"WikiData","url":"https://www.wikidata.org/w/api.php","preferredLanguages":["en"],"entityPrefix":{"url":"http://www.wikidata.org/entity/","abbreviation":"wd"},"propertyPrefix":{"url":"http://www.wikidata.org/prop/direct/","abbreviation":"wdt"},"queryService":"https://query.wikidata.org/ "},"selectedForProjection":false}],"source":{"id":"Q5879","label":"Johann Wolfgang von Goethe","prefix":{"iri":"http://www.wikidata.org/entity/","abbreviation":"wd"},"dataSource":{"name":"WikiData","url":"https://www.wikidata.org/w/api.php","preferredLanguages":["en"],"entityPrefix":{"url":"http://www.wikidata.org/entity/","abbreviation":"wd"},"propertyPrefix":{"url":"http://www.wikidata.org/prop/direct/","abbreviation":"wdt"},"queryService":"https://query.wikidata.org/ "},"selectedForProjection":false},"target":{"id":"?university","label":"Variable","prefix":{"iri":"","abbreviation":""},"dataSource":{"name":"","url":"","preferredLanguages":[],"propertyPrefix":{"url":"","abbreviation":""},"entityPrefix":{"url":"","abbreviation":""},"queryService":""},"selectedForProjection":false}}]"###;

    let result = vqg_to_query_wasm(graph, false, false);
    let select = select_line(&result);
    let vars = projection_vars(&select);

    assert_eq!(vars, vec!["*"]);
    assert!(result.contains("wd:Q5879 wdt:P69 ?university"));
}

#[test]
fn test_projection_selection_with_multiple_variables() {
    let graph = r###"[{"properties":[{"id":"?prop","label":"Variable","prefix":{"iri":"","abbreviation":""},"dataSource":{"name":"","url":"","preferredLanguages":[],"propertyPrefix":{"url":"","abbreviation":""},"entityPrefix":{"url":"","abbreviation":""},"queryService":""},"selectedForProjection":false}],"source":{"id":"?person","label":"Variable","prefix":{"iri":"","abbreviation":""},"dataSource":{"name":"","url":"","preferredLanguages":[],"propertyPrefix":{"url":"","abbreviation":""},"entityPrefix":{"url":"","abbreviation":""},"queryService":""},"selectedForProjection":true},"target":{"id":"?university","label":"Variable","prefix":{"iri":"","abbreviation":""},"dataSource":{"name":"","url":"","preferredLanguages":[],"propertyPrefix":{"url":"","abbreviation":""},"entityPrefix":{"url":"","abbreviation":""},"queryService":""},"selectedForProjection":true}}]"###;

    let result = vqg_to_query_wasm(graph, false, false);
    let select = select_line(&result);
    let vars = projection_vars(&select);

    assert!(vars.contains(&"?person"));
    assert!(vars.contains(&"?university"));
    assert!(!vars.contains(&"?prop"), "Property variable must not be projected");
    // ?prop should still appear in the triple pattern
    assert!(result.contains("?person ?prop ?university"));
}

#[test]
fn test_parse_query_with_specific_projection() {
    let query = r###"PREFIX wd: <http://www.wikidata.org/entity/>
PREFIX wdt: <http://www.wikidata.org/prop/direct/>
SELECT ?university WHERE {
     wd:Q5879 wdt:P69 ?university .
}"###;

    let result = query_to_vqg_wasm(query);
    let connections = parse_connections_json(&result);

    assert_eq!(connections.len(), 1);
    let c = &connections[0];

    // The projected variable should be present and marked as selected.
    assert_eq!(c["target"]["id"], Value::String("?university".to_string()));
    assert_eq!(c["target"]["selectedForProjection"], Value::Bool(true));
}

#[test]
fn test_backward_compatibility_without_projection_field() {
    // Old format without selected_for_projection field should default to true.
    let graph = r###"[{"properties":[{"id":"P69","label":"educated at","prefix":{"iri":"http://www.wikidata.org/prop/direct/","abbreviation":"wdt"}}],"source":{"id":"Q5879","label":"Johann Wolfgang von Goethe","prefix":{"iri":"http://www.wikidata.org/entity/","abbreviation":"wd"}},"target":{"id":"?university","label":"Variable","prefix":{"iri":"","abbreviation":""}}}]"###;

    let result = vqg_to_query_wasm(graph, false, false);
    let select = select_line(&result);
    let vars = projection_vars(&select);

    assert!(vars.contains(&"?university"));
    assert!(result.contains("wd:Q5879 wdt:P69 ?university"));
}

#[test]
fn test_query_to_vqg_empty_input() {
    assert_eq!(query_to_vqg_wasm(""), "[]");
}

#[test]
fn test_non_select_query_returns_empty_vqg() {
    let result = query_to_vqg_wasm("ASK WHERE { ?s ?p ?o . }");
    assert_eq!(result, "[]");
}

#[test]
fn test_label_service_and_prefixes_generation() {
    let graph = r###"[{"properties":[{"id":"P69","label":"educated at","prefix":{"iri":"http://www.wikidata.org/prop/direct/","abbreviation":"wdt"},"selectedForProjection":false}],"source":{"id":"Q5879","label":"Johann Wolfgang von Goethe","prefix":{"iri":"http://www.wikidata.org/entity/","abbreviation":"wd"},"selectedForProjection":false},"target":{"id":"?university","label":"Variable","prefix":{"iri":"","abbreviation":""},"selectedForProjection":true}}]"###;

    let result = vqg_to_query_wasm(graph, true, true);

    assert!(result.contains("PREFIX bd: <http://www.bigdata.com/rdf#>"));
    assert!(result.contains("PREFIX wikibase: <http://wikiba.se/ontology#>"));
    assert!(result.contains("SERVICE wikibase:label"));

    let select = select_line(&result);
    let vars = projection_vars(&select);
    assert!(vars.contains(&"?university"));
    assert!(vars.contains(&"?universityLabel"));

    // With service prefixes enabled, generated query should parse.
    assert!(
        Query::parse(&result, None).is_ok(),
        "Generated query with label service and prefixes should parse:\n{}",
        result
    );
}

#[test]
fn test_property_path_sequence_logic() {
    let graph = r###"[
        {
            "source": { "id": "?item", "label": "item", "prefix": { "iri": "", "abbreviation": "" } },
            "target": { "id": "Q5", "label": "Human", "prefix": { "iri": "http://www.wikidata.org/entity/", "abbreviation": "wd" } },
            "properties": [
                {
                    "id": "path",
                    "label": "instance of subclass of",
                    "prefix": { "iri": "", "abbreviation": "" },
                    "pathType": "sequence",
                    "properties": [
                        { "id": "P31", "label": "instance of", "prefix": { "iri": "http://www.wikidata.org/prop/direct/", "abbreviation": "wdt" } },
                        { "id": "P279", "label": "subclass of", "prefix": { "iri": "http://www.wikidata.org/prop/direct/", "abbreviation": "wdt" }, "modifier": "*" }
                    ]
                }
            ]
        }
    ]"###;

    let result = vqg_to_query_wasm(graph, false, false);
    assert!(result.contains("?item (wdt:P31/wdt:P279*) wd:Q5 ."));
}

#[test]
fn test_property_path_alternation_logic() {
    let graph = r###"[
        {
            "source": { "id": "?x", "label": "x", "prefix": { "iri": "", "abbreviation": "" } },
            "target": { "id": "TargetClass", "label": "Target", "prefix": { "iri": "http://example.org/", "abbreviation": "ex" } },
            "properties": [
                {
                    "id": "alt",
                    "label": "type or subclass",
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
    ]"###;

    let result = vqg_to_query_wasm(graph, false, false);
    assert!(result.contains("(rdf:type|rdfs:subClassOf)+ ex:TargetClass"));
}

#[test]
fn test_multiple_properties_in_one_connection() {
    let graph = r###"[
        {
            "source": { "id": "?s", "label": "S", "prefix": { "iri": "", "abbreviation": "" } },
            "target": { "id": "?o", "label": "O", "prefix": { "iri": "", "abbreviation": "" } },
            "properties": [
                { "id": "p1", "label": "P1", "prefix": { "iri": "http://example.org/", "abbreviation": "ex" } },
                { "id": "p2", "label": "P2", "prefix": { "iri": "http://example.org/", "abbreviation": "ex" } }
            ]
        }
    ]"###;

    let result = vqg_to_query_wasm(graph, false, false);
    
    // Should generate two triple patterns
    assert!(result.contains("?s ex:p1 ?o ."));
    assert!(result.contains("?s ex:p2 ?o ."));
    
    let expected = r###"PREFIX ex: <http://example.org/>
SELECT ?o ?s WHERE {
    ?s ex:p1 ?o .
    ?s ex:p2 ?o .
}"###;
    assert_sparql_equivalent(&result, expected);
}

#[test]
fn test_distinct_variable_generates_per_variable_distinct() {
    let graph = r###"[{"properties":[{"id":"P69","label":"educated at","prefix":{"iri":"http://www.wikidata.org/prop/direct/","abbreviation":"wdt"},"selectedForProjection":false}],"source":{"id":"Q5879","label":"Johann Wolfgang von Goethe","prefix":{"iri":"http://www.wikidata.org/entity/","abbreviation":"wd"},"selectedForProjection":false,"distinct":false},"target":{"id":"?university","label":"Variable","prefix":{"iri":"","abbreviation":""},"selectedForProjection":true,"distinct":true}}]"###;

    let result = vqg_to_query_wasm(graph, false, false);
    let select = select_line(&result);

    // Per-variable DISTINCT: SELECT DISTINCT(?university) WHERE { ... }
    assert!(select.contains("DISTINCT(?university)"), "Expected DISTINCT(?university) in: {}", select);
    // SELECT keyword itself should not be followed by the global DISTINCT keyword
    assert!(!select.starts_with("SELECT DISTINCT "), "Should not use global SELECT DISTINCT, got: {}", select);
}

#[test]
fn test_no_distinct_generates_plain_select() {
    let graph = r###"[{"properties":[{"id":"P69","label":"educated at","prefix":{"iri":"http://www.wikidata.org/prop/direct/","abbreviation":"wdt"},"selectedForProjection":false}],"source":{"id":"Q5879","label":"Johann Wolfgang von Goethe","prefix":{"iri":"http://www.wikidata.org/entity/","abbreviation":"wd"},"selectedForProjection":false,"distinct":false},"target":{"id":"?university","label":"Variable","prefix":{"iri":"","abbreviation":""},"selectedForProjection":true,"distinct":false}}]"###;

    let result = vqg_to_query_wasm(graph, false, false);
    let select = select_line(&result);

    assert!(!select.contains("DISTINCT"), "Expected plain SELECT but got: {}", select);
    assert!(select.contains("?university"));
}

#[test]
fn test_parse_select_distinct_query_does_not_set_per_variable_distinct_flag() {
    // Importing SELECT DISTINCT ?university does NOT set distinct=true on individual variables.
    // Per-variable distinct is only set via the UI checkbox; the global DISTINCT keyword is ignored on import.
    let query = r###"PREFIX wd: <http://www.wikidata.org/entity/>
PREFIX wdt: <http://www.wikidata.org/prop/direct/>
SELECT DISTINCT ?university WHERE {
    wd:Q5879 wdt:P69 ?university .
}"###;

    let result = query_to_vqg_wasm(query);
    let connections = parse_connections_json(&result);

    assert_eq!(connections.len(), 1);
    let c = &connections[0];

    assert_eq!(c["target"]["id"], Value::String("?university".to_string()));
    assert_eq!(c["target"]["selectedForProjection"], Value::Bool(true));
    assert_eq!(c["target"]["distinct"], Value::Bool(false));
}

#[test]
fn test_parse_non_distinct_query_does_not_set_distinct_flag() {
    let query = r###"PREFIX wd: <http://www.wikidata.org/entity/>
PREFIX wdt: <http://www.wikidata.org/prop/direct/>
SELECT ?university WHERE {
    wd:Q5879 wdt:P69 ?university .
}"###;

    let result = query_to_vqg_wasm(query);
    let connections = parse_connections_json(&result);

    assert_eq!(connections.len(), 1);
    let c = &connections[0];

    assert_eq!(c["target"]["id"], Value::String("?university".to_string()));
    assert_eq!(c["target"]["distinct"], Value::Bool(false));
}

#[test]
fn test_distinct_only_applies_when_variable_is_selected_for_projection() {
    // distinct=true but selectedForProjection=false → DISTINCT(?var) must NOT appear
    let graph = r###"[{"properties":[{"id":"P69","label":"educated at","prefix":{"iri":"http://www.wikidata.org/prop/direct/","abbreviation":"wdt"},"selectedForProjection":false}],"source":{"id":"Q5879","label":"Goethe","prefix":{"iri":"http://www.wikidata.org/entity/","abbreviation":"wd"},"selectedForProjection":false,"distinct":false},"target":{"id":"?university","label":"Variable","prefix":{"iri":"","abbreviation":""},"selectedForProjection":false,"distinct":true}}]"###;

    let result = vqg_to_query_wasm(graph, false, false);

    assert!(!result.contains("DISTINCT"), "DISTINCT should not appear when variable is not selected for projection: {}", result);
}

#[test]
fn test_mixed_distinct_and_non_distinct_variables() {
    // ?university is distinct, ?person is not → only ?university gets DISTINCT(...)
    let graph = r###"[{"properties":[{"id":"P69","label":"educated at","prefix":{"iri":"http://www.wikidata.org/prop/direct/","abbreviation":"wdt"},"selectedForProjection":false}],"source":{"id":"?person","label":"Variable","prefix":{"iri":"","abbreviation":""},"selectedForProjection":true,"distinct":false},"target":{"id":"?university","label":"Variable","prefix":{"iri":"","abbreviation":""},"selectedForProjection":true,"distinct":true}}]"###;

    let result = vqg_to_query_wasm(graph, false, false);
    let select = select_line(&result);

    assert!(select.contains("DISTINCT(?university)"), "Expected DISTINCT(?university) in: {}", select);
    // ?person should appear as a plain variable (no DISTINCT wrapper)
    assert!(select.contains("?person"), "Expected ?person in: {}", select);
    assert!(!select.contains("DISTINCT(?person)"), "?person should not be wrapped in DISTINCT: {}", select);
}

#[test]
fn test_label_vars_not_distinct_even_when_base_var_is_distinct() {
    // With label service, ?universityLabel must NOT be wrapped in DISTINCT
    let graph = r###"[{"properties":[{"id":"P69","label":"educated at","prefix":{"iri":"http://www.wikidata.org/prop/direct/","abbreviation":"wdt"},"selectedForProjection":false}],"source":{"id":"Q5879","label":"Goethe","prefix":{"iri":"http://www.wikidata.org/entity/","abbreviation":"wd"},"selectedForProjection":false,"distinct":false},"target":{"id":"?university","label":"Variable","prefix":{"iri":"","abbreviation":""},"selectedForProjection":true,"distinct":true}}]"###;

    let result = vqg_to_query_wasm(graph, true, true);
    let select = select_line(&result);

    assert!(select.contains("DISTINCT(?university)"), "Expected DISTINCT(?university) in: {}", select);
    assert!(!select.contains("DISTINCT(?universityLabel)"), "Label variable must not be wrapped in DISTINCT: {}", select);
    assert!(select.contains("?universityLabel"), "Label variable should still appear: {}", select);
}
