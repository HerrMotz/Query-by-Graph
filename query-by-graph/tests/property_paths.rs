use query_by_graph::{query_to_vqg_wasm, vqg_to_query_wasm};
use serde_json::json;

#[test]
fn test_complex_property_path_decomposition() {
    let query = "PREFIX ex: <http://example.org/> SELECT * WHERE { ?s ex:p1/ex:p2*|ex:p3? ?o . }";
    let json_str = query_to_vqg_wasm(query);
    let v: serde_json::Value = serde_json::from_str(&json_str).unwrap();
    
    // Expecting an alternation at the top level
    let properties = &v[0]["properties"];
    assert_eq!(properties[0]["pathType"], "alternation");
    
    let sub_props = &properties[0]["properties"];
    assert_eq!(sub_props.as_array().unwrap().len(), 2);
    
    // First part: ex:p1/ex:p2*
    assert_eq!(sub_props[0]["pathType"], "sequence");
    let seq_props = &sub_props[0]["properties"];
    assert_eq!(seq_props[0]["id"], "<http://example.org/p1>");
    assert_eq!(seq_props[1]["id"], "<http://example.org/p2>");
    assert_eq!(seq_props[1]["modifier"], "*");
    
    // Second part: ex:p3?
    assert_eq!(sub_props[1]["id"], "<http://example.org/p3>");
    assert_eq!(sub_props[1]["modifier"], "?");
}

#[test]
fn test_user_reported_issue_decomposition() {
    let query = r###"
        PREFIX wdt: <http://www.wikidata.org/prop/direct/>
        SELECT ?1 ?1Label ?2 ?2Label WHERE {
            ?1 (wdt:P31|wdt:P279)+ ?2 .
            SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en". }
        }
    "###;
    let json_str = query_to_vqg_wasm(query);
    println!("Resulting JSON:\n{}", json_str);
    let v: serde_json::Value = serde_json::from_str(&json_str).unwrap();
    
    assert_eq!(v.as_array().unwrap().len(), 1);
    let connection = &v[0];
    let properties = &connection["properties"];
    
    // We expect decomposition: root property should have modifier "+" and pathType "alternation"
    // OR root property has modifier "+" and ONE child which is the alternation.
    // Based on my implementation of property_path_to_property:
    /*
        PropertyPathExpression::OneOrMore(inner) => {
            let mut p = property_path_to_property(inner);
            p.modifier = Some("+".to_string());
            p
        }
    */
    // So p should have path_type: alternation.
    
    assert_eq!(properties[0]["modifier"], "+");
    assert_eq!(properties[0]["pathType"], "alternation");
    assert_eq!(properties[0]["properties"].as_array().unwrap().len(), 2);
}

#[test]
fn test_triple_with_path_syntax_in_bgp_context() {
    // This is NOT a property path according to SPARQL 1.1 grammar if it's just a TriplePattern,
    // but many parsers handle it. Spargebra treats it as GraphPattern::Path if it uses path operators.
    let query = "SELECT * WHERE { ?s <http://example.org/p1>|<http://example.org/p2> ?o . }";
    let json_str = query_to_vqg_wasm(query);
    let v: serde_json::Value = serde_json::from_str(&json_str).unwrap();
    
    let properties = &v[0]["properties"];
    assert_eq!(properties[0]["pathType"], "alternation");
}

#[test]
fn test_query_with_no_projection_variables_and_path() {
    // Using a path that cannot be simplified to multiple triples
    // Parentheses around the whole path might force it to be treated as one Path expression
    let query = "SELECT * WHERE { ?s <http://example.org/p1>|<http://example.org/p2> ?o . }";
    let json_str = query_to_vqg_wasm(query);
    println!("JSON for SELECT * with path:\n{}", json_str);
    let v: serde_json::Value = serde_json::from_str(&json_str).unwrap();
    
    assert_eq!(v.as_array().unwrap().len(), 1);
    assert_eq!(v[0]["properties"][0]["pathType"], "alternation");
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
fn test_vql_property_path() {
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

#[test]
fn test_wikidata_alternation_plus_modifier() {
    let connections = json!([
        {
          "properties": [
            {
              "id": "path",
              "label": "subclass of|instance of",
              "prefix": {
                "iri": "",
                "abbreviation": ""
              },
              "pathType": "alternation",
              "modifier": "+",
              "properties": [
                {
                  "id": "P279",
                  "label": "subclass of",
                  "description": "this item is a subclass (subset) of that item; ALL instances of this item are instances of that item; different from P31 (instance of), e.g.: volcano is a subclass of mountain; Everest is an instance of mountain",
                  "prefix": {
                    "iri": "http://www.wikidata.org/prop/direct/",
                    "abbreviation": "wdt"
                  },
                  "dataSource": {
                    "name": "WikiData",
                    "uri": "https://www.wikidata.org/w/api.php",
                    "preferredLanguages": [
                      "en"
                    ],
                    "itemPrefix": {
                      "iri": "http://www.wikidata.org/entity/",
                      "abbreviation": "wd"
                    },
                    "propertyPrefix": {
                      "iri": "http://www.wikidata.org/prop/direct/",
                      "abbreviation": "wdt"
                    },
                    "queryService": "https://query.wikidata.org/"
                  }
                },
                {
                  "id": "P31",
                  "label": "instance of",
                  "description": "type to which this subject corresponds/belongs. Different from P279 (subclass of); for example: K2 is an instance of mountain; volcano is a subclass of mountain",
                  "prefix": {
                    "iri": "http://www.wikidata.org/prop/direct/",
                    "abbreviation": "wdt"
                  },
                  "dataSource": {
                    "name": "WikiData",
                    "uri": "https://www.wikidata.org/w/api.php",
                    "preferredLanguages": [
                      "en"
                    ],
                    "itemPrefix": {
                      "iri": "http://www.wikidata.org/entity/",
                      "abbreviation": "wd"
                    },
                    "propertyPrefix": {
                      "iri": "http://www.wikidata.org/prop/direct/",
                      "abbreviation": "wdt"
                    },
                    "queryService": "https://query.wikidata.org/"
                  }
                }
              ]
            }
          ],
          "source": {
            "id": "?1",
            "label": "Variable",
            "description": "Variable Entity",
            "prefix": {
              "iri": "",
              "abbreviation": ""
            },
            "dataSource": {
              "name": "",
              "uri": "",
              "preferredLanguages": [],
              "propertyPrefix": {
                "iri": "",
                "abbreviation": ""
              },
              "itemPrefix": {
                "iri": "",
                "abbreviation": ""
              },
              "queryService": ""
            },
            "selectedForProjection": true
          },
          "target": {
            "id": "?2",
            "label": "Variable",
            "description": "Variable Entity",
            "prefix": {
              "iri": "",
              "abbreviation": ""
            },
            "dataSource": {
              "name": "",
              "uri": "",
              "preferredLanguages": [],
              "propertyPrefix": {
                "iri": "",
                "abbreviation": ""
              },
              "itemPrefix": {
                "iri": "",
                "abbreviation": ""
              },
              "queryService": ""
            },
            "selectedForProjection": true
          }
        }
    ]);

    let query = vqg_to_query_wasm(&connections.to_string(), false, false);
    println!("Query:\n{}", query);
    // Expecting (wdt:P279|wdt:P31)+
    assert!(query.contains("(wdt:P279|wdt:P31)+"));
    assert!(query.contains("SELECT ?1 ?2 WHERE"));
    assert!(query.contains("?1 ((wdt:P279|wdt:P31)+) ?2"));
}
