use query_by_graph::query_to_vqg_wasm;

#[test]
fn test_invalid_query_resilience() {
    let invalid_query = "some mumbo jumbo";
    // This should not panic or cause index out of bounds
    let result = query_to_vqg_wasm(invalid_query);
    assert_eq!(result, "[]");
}

#[test]
fn test_partially_invalid_query_resilience() {
    let query = "SELECT * WHERE { ?s ?p ?o . some nonsense }";
    let result = query_to_vqg_wasm(query);
    // Even if it fails to parse, it should not panic
    // According to src/lib.rs, if it fails to parse, it tries to add prefixes and retry.
    // If it still fails, it calls _helper(Err(error)) which returns vec![]
    assert_eq!(result, "[]");
}

#[test]
fn test_invalid_json_to_query_wasm() {
    use query_by_graph::vqg_to_query_wasm;
    let invalid_json = "not a json";
    let result = vqg_to_query_wasm(invalid_json, false, false);
    assert_eq!(result, "");
}
