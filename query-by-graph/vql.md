# VQG Language Features and JSON Schema

This document describes the language features supported by the Visual Query Graph (VQG) processor and how they are represented in the JSON format used for conversion to and from SPARQL.

## Overview

The library converts between a JSON-based graph representation and SPARQL queries. The graph consists of a list of **Connections**, where each connection represents one or more triples (or property paths) between a **Source** entity and a **Target** entity.

## Core Concepts

### Entity
An `Entity` represents a node in the graph (Subject or Object in RDF).

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | `string` | The identifier of the entity. Can be a prefixed ID (e.g., `Q5`), a full IRI (e.g., `<http://.../Q5>`), or a variable (e.g., `?item`). |
| `label` | `string` | A human-readable label for the entity (used for comments in SPARQL). |
| `prefix` | `Prefix` | The namespace prefix information for the entity. |
| `selectedForProjection` | `boolean` | If true and the `id` is a variable, it will be included in the `SELECT` clause. |

### Property
A `Property` represents the edge between entities. It supports complex [SPARQL Property Paths](https://www.w3.org/TR/sparql11-query/#propertypaths).

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | `string` | The identifier of the property or variable. |
| `label` | `string` | Human-readable label. |
| `prefix` | `Prefix` | Namespace prefix information. |
| `selectedForProjection` | `boolean` | If true and the `id` is a variable, it will be included in the `SELECT` clause. |
| `properties` | `Property[]` | (Optional) Nested properties for complex paths (sequences or alternations). |
| `pathType` | `string` | (Optional) Specifies the path type: `"sequence"` (default) or `"alternation"`. |
| `modifier` | `string` | (Optional) SPARQL path modifier: `*` (zero or more), `+` (one or more), `?` (zero or one). |

### Connection
A `Connection` links a `source` entity to a `target` entity via one or more `properties`.

| Field | Type | Description |
| :--- | :--- | :--- |
| `source` | `Entity` | The subject of the triple(s). |
| `target` | `Entity` | The object of the triple(s). |
| `properties` | `Property[]` | A list of properties. Each property results in a separate triple pattern between the source and target. |

---

## Language Features

### 1. Basic Triple Patterns
A simple connection between two entities with a single property.

**RDF Mapping:** `source property target .`

**JSON Snippet:**
```json
[
  {
    "source": {
      "id": "Q5879",
      "label": "Johann Wolfgang von Goethe",
      "prefix": { "iri": "http://www.wikidata.org/entity/", "abbreviation": "wd" }
    },
    "target": {
      "id": "Q154804",
      "label": "Leipzig University",
      "prefix": { "iri": "http://www.wikidata.org/entity/", "abbreviation": "wd" }
    },
    "properties": [
      {
        "id": "P69",
        "label": "educated at",
        "prefix": { "iri": "http://www.wikidata.org/prop/direct/", "abbreviation": "wdt" }
      }
    ]
  }
]
```
**Generated SPARQL:**
```sparql
PREFIX wd: <http://www.wikidata.org/entity/>
PREFIX wdt: <http://www.wikidata.org/prop/direct/>

SELECT * WHERE {
    wd:Q5879 wdt:P69 wd:Q154804 .
    # Johann Wolfgang von Goethe -- [educated at] -> Leipzig University
}
```

### 2. Variables and Projection
Variables are denoted by a `?` prefix. The `selectedForProjection` field controls which variables appear in the `SELECT` list.

**JSON Snippet:**
```json
{
  "source": { "id": "?item", "label": "item", "selectedForProjection": true, "prefix": { "iri": "", "abbreviation": "" } },
  "target": { "id": "Q5", "label": "Human", "selectedForProjection": false, "prefix": { "iri": "http://www.wikidata.org/entity/", "abbreviation": "wd" } },
  "properties": [
    { "id": "P31", "label": "instance of", "prefix": { "iri": "http://www.wikidata.org/prop/direct/", "abbreviation": "wdt" } }
  ]
}
```
**Generated SPARQL:** `SELECT ?item WHERE { ?item wdt:P31 wd:Q5 . }`

### 3. Property Paths: Sequence
Sequences represent multiple hops in the graph.

**RDF Standard:** `elt1 / elt2`

**JSON Snippet:**
```json
{
  "properties": [
    {
      "id": "path",
      "pathType": "sequence",
      "properties": [
        { "id": "P31", "prefix": { "abbreviation": "wdt", "iri": "http://www.wikidata.org/prop/direct/" } },
        { "id": "P279", "prefix": { "abbreviation": "wdt", "iri": "http://www.wikidata.org/prop/direct/" }, "modifier": "*" }
      ]
    }
  ]
}
```
**Generated SPARQL:** `?source wdt:P31/(wdt:P279*) ?target .`

### 4. Property Paths: Alternation
Alternations represent a choice between properties.

**RDF Standard:** `elt1 | elt2`

**JSON Snippet:**
```json
{
  "properties": [
    {
      "id": "path",
      "pathType": "alternation",
      "modifier": "+",
      "properties": [
        { "id": "type", "prefix": { "abbreviation": "rdf", "iri": "http://www.w3.org/1999/02/22-rdf-syntax-ns#" } },
        { "id": "subClassOf", "prefix": { "abbreviation": "rdfs", "iri": "http://www.w3.org/2000/01/rdf-schema#" } }
      ]
    }
  ]
}
```
**Generated SPARQL:** `?source (rdf:type|rdfs:subClassOf)+ ?target .`

### 5. Wikidata Label Service
The library can automatically add the Wikibase label service to provide human-readable labels for variables.

**SPARQL Feature:** `SERVICE wikibase:label { ... }`

When `add_label_service` is enabled:
- `?variable` in projection also adds `?variableLabel`.
- A `SERVICE wikibase:label` block is added to the `WHERE` clause.

---

## Schema Reference

### Prefix
```json
{
  "iri": "string",
  "abbreviation": "string"
}
```
If `iri` is empty, the `id` is treated as a literal or full IRI.
