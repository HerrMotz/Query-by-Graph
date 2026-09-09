# Query by Graph (QuebyG) Front-End

## Tech Stack / Developer notes

This project uses Vue 3, TypeScript and Rust in Vite. Learn more
about the recommended Project Setup and IDE Support in the
[Vue Docs TypeScript Guide](https://vuejs.org/guide/typescript/overview.html#project-setup).

For Rust, I recommend using Visual Studio Code.

This application _solely runs in the browser_. This repository
does not contain a backend. The data fetching can be configured
in the environment files. See [Vite Docs](https://vitejs.dev/guide/env-and-mode)
for more details.

## Why use Rust (as WASM)?

The choice to write the conversion algorithm from "Visual Query"
to SPARQL in Rust is based on the following reasons.

The algorithm should be:

- reusable,
- fast and
- provable to be correct.

The Rust compiler offers many features, that assist in achieving
these goals.

## Installation/Requirements for Building

The application consist of two parts:

- The "Query by Graph" conversion algorithm, written in Rust, compiled as WASM
- The Vue UI, built with Vite

Therefore, we first need to build the Rust WASM (as a package) and then
the Vue UI. For more info on a "WASM with Vite"-projects, look [here](https://github.com/shadanan/vite-rust-wasm).

For building, you will need the following tools:

- Node.js (node, npm)
- Rust with Cargo

### Vite+Vue Frontend

To install all dependencies, run the following command:

```bash
npm install
```

### Rust

To install the Rust dependencies, run the following command:

```bash
cargo install wasm-pack
```

## Run Scripts

### Running the Application for Development (hot-reload)

```bash
wasm-pack build
npm run dev
```

### Building for Production

```bash
wasm-pack build
npm run build
```

The production files are put into the `dist` folder.

For other scripts see `package.json` file.

## Program description

### Functionality

It allows the user to build simple SPARQL queries using a
visual query builder. The query can then be run
against a SPARQL endpoint.

### Feature List

| Feature                                                     | Description                                                                                                      | Implemented |
|-------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------|-------------|
| Building SPARQL SELECT queries                              | with arbitrary properties                                                                                        | Yes         |
| Adding Label Service statements                             | e.g. SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en". }                          | No          |
| Running SPARQL queries                                      | against a SPARQL endpoint                                                                                        | No          |
| Displaying the results of the SPARQL query                  | in a table                                                                                                       | No          |
| Exporting/Saving and Importing/Loading queries              | making the box below the visual builder editable, rebuild visual query from the entered contents                 | No          |
| Running queries in the background and return COUNT(results) | https://blog.factgrid.de/wp-content/uploads/2022/04/Mitglieder-der-Illuminaten-und-Regionsverteilung-768x411.png | No          |
| Translate SPARQL Query to natural language                  | [like here](https://blog.factgrid.de/wp-content/uploads/2022/04/Ausbildung-der-Vater-der-Jena-Studenten.png)     | No          |
| Qualifiers                                                  | [like here](https://blog.factgrid.de/wp-content/uploads/2022/04/Jena-Studium-von-bis-768x443.png)                | No          |

### Graph Legend

- **Node**: ontology individual (Qxxxx)
- **Connection**: property (Pxxxx)

## To-Do

- [x] Drawing labels on the connections
- [x] Inject custom data into the custom connection component
- [x] Make the connections selectable and deletable
- [x] Adding and deleting individuals
- [x] Variable Properties
- [x] Adding variable individuals
- [x] Directed properties/edges
- [ ] Connect constant strings using properties (e.g. given name = "Goethe")
- [ ] Think of a way to recommend available properties to the user
- [ ] Build this property recommending tool
- [x] Build a SPARQL select query
- [x] SPARQL syntax highlighter
- [x] Multiple outputs/inputs
- [ ] Translate SPARQL to Graph
- [ ] Make the text input editable
- [ ] Visualise query results in a graph

- [ ] Allow naming variables
- [ ] Fix text box sizes
- [ ] Make heading more pointy

- [ ] Prefixing
- [ ] also for multiple databases


- [ ] Explain the UI with hints

## Might-Do

- [ ] Fix, that disconnecting a connection relabels it with the currently selected property
- [ ] Should I allow duplicate individuals?
- [ ] Automatically arrange nodes on button press
