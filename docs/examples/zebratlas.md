# Zebratlas (optional)

[Zebratlas](https://zebratlas.org) connects rare-disease knowledge and its evidence.
Its read-only RDF endpoint is `https://zebratlas.org/sparql`; it is not a Wikibase API.

From `app/`, enable the preset when starting or building:

```bash
npm ci
VITE_ENABLE_ZEBRATLAS=true npm run dev
# or: VITE_ENABLE_ZEBRATLAS=true npm run build
```

In **Manage Data Sources**, reset to defaults once if you already have saved sources.
Select **Zebratlas** and paste [zebratlas.rq](zebratlas.rq) into the query editor.
After editing the graph, append `LIMIT 50` to the text query and click **Run**.
Run opens the endpoint with a URL-encoded `query` parameter. The endpoint must be live
and allow browser CORS for language-server completions. A redirect or HTML response is
not a successful SPARQL result. This integration is opt-in while deployment is in progress.

The graph selectors offer a small local vocabulary, variables, quoted literals and
explicit prefixed or full HTTP(S) IRIs. They do not search a MediaWiki API or invent
identifiers from names. Online editor completions use bounded `VALUES` queries for that
same vocabulary, without Blazegraph extensions. No Wikibase label service is generated.
The existing graph importer does not support `LIMIT` or `ORDER BY`. Add a limit
after graph editing, before running; later graph edits replace the text query.

| Prefix | Namespace |
| --- | --- |
| `raid` | `https://w3id.org/rare-disease-atlas/id/` |
| `ra` | `https://w3id.org/rare-disease-atlas/vocab#` |
| `rdf` | `http://www.w3.org/1999/02/22-rdf-syntax-ns#` |
| `rdfs` | `http://www.w3.org/2000/01/rdf-schema#` |
| `prov` | `http://www.w3.org/ns/prov#` |
| `dcterms` | `http://purl.org/dc/terms/` |

The release types graph nodes as `ra:Node`, distinguished by the literal `ra:nodeKind`,
and assertions as `ra:Edge`; it does not define `ra:Disease` or `ra:Gene` classes.
The preset includes `ra:has_associated_gene`, identifiers, labels and provenance
predicates for source URL, record locator, retrieval time, version and SHA-256.
Release identifiers are percent-encoded: STXBP1 is `raid:HGNC%3A11444`.
Returned associations are research leads; inspect the linked sources for their meaning.

The vocabulary and example derive from the pinned Zebratlas RDF exporter and example
query recorded in [zebratlas.prov.json](zebratlas.prov.json), including source URLs,
retrieval time, version, hashes and record locators. Dataset coverage and source licences
are determined by Zebratlas's licensed release.

Zebratlas credits **Daniel Motz's Query by Graph** for its query-graph work; this optional
preset brings Zebratlas's evidence graph back to Query by Graph. No code is copied from
Zebratlas, and Query by Graph's existing licence terms apply.

Verify locally (Node.js 22.18+ or 24, Rust and wasm-pack):

```bash
cd app
node --experimental-strip-types --test tests/zebratlas.mjs
cargo test -j 8 -p query-by-graph
VITE_ENABLE_ZEBRATLAS=true npm run build
```
