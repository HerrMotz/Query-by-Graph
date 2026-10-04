import type {WikibaseDataSource} from "../types/WikibaseDataSource.ts";

// Vocabulary from Zebratlas's licensed RDF release, not Wikibase Q/P ids.
// See docs/examples/zebratlas.md for the pinned source and its provenance.
export const zebratlasDataSource: WikibaseDataSource = {
    name: "Zebratlas",
    kind: 'sparql',
    uri: "",
    preferredLanguages: ['en'],
    itemPrefix: {
        iri: "https://w3id.org/rare-disease-atlas/id/",
        abbreviation: "raid"
    },
    propertyPrefix: {
        iri: "https://w3id.org/rare-disease-atlas/vocab#",
        abbreviation: "ra"
    },
    queryService: "https://zebratlas.org/sparql",
    sparqlEndpoint: "https://zebratlas.org/sparql",
    prefixMap: {
        rdf: "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
        rdfs: "http://www.w3.org/2000/01/rdf-schema#",
        prov: "http://www.w3.org/ns/prov#",
        dcterms: "http://purl.org/dc/terms/"
    },
    vocabulary: [
        {id: 'ra:Node', label: 'Node', type: 'item'},
        {id: 'ra:Edge', label: 'Edge', type: 'item'},
        {id: 'prov:Entity', label: 'Evidence entity', type: 'item'},
        {id: 'prov:Activity', label: 'Activity', type: 'item'},
        {id: 'raid:HGNC%3A11444', label: 'STXBP1', type: 'item'},
        {id: 'rdf:type', label: 'Type', type: 'property'},
        {id: 'rdfs:label', label: 'Label', type: 'property'},
        {id: 'ra:nodeKind', label: 'Node kind', type: 'property'},
        {id: 'ra:has_associated_gene', label: 'Associated gene', type: 'property'},
        {id: 'ra:edgeKind', label: 'Evidence kind', type: 'property'},
        {id: 'dcterms:identifier', label: 'Identifier', type: 'property'},
        {id: 'dcterms:source', label: 'Source', type: 'property'},
        {id: 'dcterms:hasVersion', label: 'Version', type: 'property'},
        {id: 'prov:wasDerivedFrom', label: 'Derived from', type: 'property'},
        {id: 'ra:recordLocator', label: 'Record locator', type: 'property'},
        {id: 'ra:retrievedAt', label: 'Retrieved at', type: 'property'},
        {id: 'ra:sha256', label: 'SHA-256', type: 'property'}
    ]
}
