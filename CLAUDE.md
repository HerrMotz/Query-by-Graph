# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository layout

- `app/` — the entire application (Vue 3 + TypeScript frontend and the Rust/WASM conversion library live in the *same* crate/npm package root). **All npm/cargo commands must be run from `app/`, not the repo root.**
- `publication/` — Typst sources for the bachelor thesis, compiled by `.github/workflows/typst-compile.yaml` on tag push.
- `app/vql.md` — reference spec for the VQG JSON schema and supported SPARQL language features. Update this when changing the Rust data model.

## Commands (run from `app/`)

```bash
npm install                 # JS deps
cargo install wasm-pack     # required once; build scripts invoke wasm-pack

npm run dev                 # wasm-pack build && vite  (dev server, hot reload)
npm run build               # wasm-pack build && vue-tsc -b && vite build  -> dist/
npm run preview             # serve the production build
./build                     # same as npm run build

cargo test                  # native Rust tests (tests/logic.rs, resilience.rs, property_paths.rs)
cargo test --test logic test_name_substring   # a single native test
npm run test-rs             # wasm-pack test --chrome (tests/web.rs, browser-only)
```

There is no JS test runner and no linter; type checking happens via `vue-tsc -b` inside `npm run build`, which is also what CI (`.github/workflows/vite-compile.yaml`, Node 22) runs.

`wasm-pack build` regenerates `app/pkg/` (gitignored). The frontend imports the WASM bindings from `../pkg`, so `pkg/` must exist before Vite can resolve `App.vue`. If you edit `src/lib.rs` and only run `vite`, you will be running stale WASM.

## Architecture

The app is **browser-only — there is no backend.** It talks directly to public Wikibase APIs and SPARQL endpoints.

Three layers:

1. **Rust → WASM conversion core (`app/src/lib.rs`, ~560 lines).** The single source of truth for the VQG ⇄ SPARQL mapping. Exposes exactly two `#[wasm_bindgen]` functions, both string-in/string-out over JSON:
   - `vqg_to_query_wasm(json, add_label_service, add_label_service_prefixes)` — graph → SPARQL.
   - `query_to_vqg_wasm(query)` — SPARQL → graph, parsing with `spargebra`. It is deliberately **panic-free and lossy-tolerant**: unparseable input returns `"[]"` rather than erroring (see `tests/resilience.rs`). Parsing retries after injecting known prefixes before giving up.

   The data model is `Vec<Connection>`, where `Connection { source: Entity, target: Entity, properties: Vec<Property> }`. `Property` is recursive (`properties` + `pathType` of `sequence`/`alternation` + `modifier` `*`/`+`/`?`) to represent SPARQL property paths. Serde uses `rename_all = "camelCase"`, so Rust `selected_for_projection` is `selectedForProjection` in JSON/TS. Fields added later carry `#[serde(default)]` for backward compatibility with saved graphs — keep that pattern.

   Native integration tests import the crate as `query_by_graph::…`, so anything under test must stay `pub`. `tests/logic.rs` compares queries by re-parsing both sides with `spargebra` and comparing the ASTs, not by string equality.

2. **Rete graph editor (`app/src/lib/rete/editor.ts`, ~670 lines).** `createEditor()` wires up the whole `rete` v2 stack (area, connection, path, history, auto-arrange, vue render plugins) and returns the editor's public API — notably `importConnections(connections)`, used to rebuild the visual graph from a parsed SPARQL query. Custom Vue components are injected as rete presets: `EntityNode.vue` (node), `PropertyConnection.vue` (edge), `EntitySelectorInputControl.vue` (control).

3. **Vue UI (`app/src/App.vue`).** Owns the round trip: graph changes are debounced into `vqg_to_query_wasm` to update the Monaco editor; edits in the Monaco editor go through `query_to_vqg_wasm` and back into `editor.importConnections`. Beware of feedback loops when touching this — `App.vue` already guards against re-importing a graph it just exported.

## Data sources

A `WikibaseDataSource` (`app/src/lib/types/WikibaseDataSource.ts`) bundles the entity-search API URI, the query-service URL, preferred languages, and the item/property prefix pairs (e.g. `wd:`/`wdt:` for Wikidata). Three defaults ship in `app/src/lib/constants/index.ts`: Wikidata, FactGrid, MiMoText.

`app/src/store.ts` is a hand-rolled `ref`-based store (no Pinia) that mirrors data sources into `localStorage` under the keys `dataSources` and `selectedDataSource`. localStorage is non-reactive, so every mutation must write to *both* the ref and localStorage — follow the existing helpers rather than writing localStorage directly.

Entity lookup and label resolution go through `app/src/lib/wikidata/WikibaseDataService.ts` (axios against the Wikibase `api.php`); query execution against the SPARQL endpoint is in `queryDataService.ts`.

The prefixes chosen by the active data source flow into the graph nodes, and from there into the generated SPARQL — so a prefix bug usually originates in the data source config, not in `lib.rs`.

## Conventions

- SPARQL syntax highlighting is a custom highlight.js language in `app/src/lib/highlight/sparql.ts`.
- Styling is Tailwind v4 (via `@tailwindcss/postcss`) plus `@headlessui/vue` for popovers.
- Do not add a `Co-Authored-By: Claude` trailer to commits in this repository.
