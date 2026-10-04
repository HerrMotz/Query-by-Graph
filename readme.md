# Query by Graph

Query by Graph allows its users to build a visual query graph, which is converted into an adequate SPARQL query for Wikibase instances.
The motivation for this work came from [Olaf Simons](https://blog.factgrid.de/archives/2596).

- You can find the app [here (query.daniel-motz.de)](https://query.daniel-motz.de).
- You can download the publication [here](https://www.daniel-motz.de/static-content/Query-by-Graph-Bachelor-Thesis.pdf).

## Related Works
- [Sparnatural](https://github.com/sparna-git/Sparnatural)
- [RDF Explorer](https://rdfexplorer.org/)

## Optional Zebratlas source

Query by Graph can also build queries for [Zebratlas](https://zebratlas.org)'s
read-only rare-disease RDF graph. Enable it with `VITE_ENABLE_ZEBRATLAS=true`;
the Wikibase defaults remain available. See the [setup and example query](docs/examples/zebratlas.md).

## Language Features and JSON Schema
For detailed documentation on supported language features and the VQG JSON schema, see [vql.md](app/vql.md).

## Star History

[![Star History Chart](https://api.star-history.com/image?repos=herrmotz/query-by-graph&type=date)](https://www.star-history.com/?repos=herrmotz%2Fquery-by-graph&type=date)
