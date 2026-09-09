import type {WikibaseDataSource} from "../types/WikibaseDataSource.ts";
import type {SparqlBackend} from "./sparqlLanguageServer.ts";

/**
 * Describe the selected data source to the SPARQL language server, so that it
 * can offer completions and hover information for the entities and properties
 * of that Wikibase.
 *
 * Returns `undefined` when no endpoint can be determined; the language server
 * then falls back to what needs no endpoint (keywords, variables, formatting).
 */
export function backendFromDataSource(dataSource: WikibaseDataSource): SparqlBackend | undefined {
    const url = sparqlEndpointOf(dataSource);
    if (!url) return undefined;

    const prefixMap: Record<string, string> = {};
    for (const prefix of [dataSource.itemPrefix, dataSource.propertyPrefix]) {
        if (prefix?.abbreviation && prefix?.iri) prefixMap[prefix.abbreviation] = prefix.iri;
    }

    return {
        name: dataSource.name || url,
        url,
        // All Wikibase query services ship with the Blazegraph based WDQS.
        engine: 'Blazegraph',
        prefixMap,
        queries: completionQueries(dataSource),
    };
}

function sparqlEndpointOf(dataSource: WikibaseDataSource): string | undefined {
    if (dataSource.sparqlEndpoint) return dataSource.sparqlEndpoint;
    // Data sources configured before this field existed only know the query
    // service UI; its endpoint conventionally sits under "sparql".
    if (dataSource.queryService) return dataSource.queryService.replace(/\/?$/, '/') + 'sparql';
    return undefined;
}

function apiHostOf(dataSource: WikibaseDataSource): string | undefined {
    try {
        return new URL(dataSource.uri).host;
    } catch {
        return undefined;
    }
}

/**
 * Completion and hover queries for the language server, one Tera template per
 * completion type (see https://docs.qlue-ls.com/05_completion_queries/).
 *
 * Every Wikibase query service exposes the entity search of its MediaWiki API
 * as `wikibase:mwapi`, which is the only search that stays fast on the public
 * endpoints — counting triples to rank candidates times out on Wikidata. The
 * consequence is that the context sensitive templates are the same as the
 * insensitive ones: the surrounding triple patterns are not used.
 */
function completionQueries(dataSource: WikibaseDataSource): Record<string, string> | undefined {
    const apiHost = apiHostOf(dataSource);
    const itemIri = dataSource.itemPrefix?.iri;
    const propertyIri = dataSource.propertyPrefix?.iri;
    if (!apiHost || !itemIri || !propertyIri) return undefined;

    const language = dataSource.preferredLanguages?.[0] ?? 'en';
    const items = entitySearchQuery(apiHost, language, itemIri, propertyIri, 'item');
    const properties = entitySearchQuery(apiHost, language, itemIri, propertyIri, 'property');

    return {
        subjectCompletion: items,
        objectCompletionContextSensitive: items,
        objectCompletionContextInsensitive: items,
        valuesCompletionContextSensitive: items,
        valuesCompletionContextInsensitive: items,
        predicateCompletionContextSensitive: properties,
        predicateCompletionContextInsensitive: properties,
        hover: hoverQuery(language, itemIri, propertyIri),
    };
}

const WIKIBASE_PREFIXES = `PREFIX wikibase: <http://wikiba.se/ontology#>
PREFIX bd: <http://www.bigdata.com/rdf#>
PREFIX mwapi: <https://www.mediawiki.org/ontology#API/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX schema: <http://schema.org/>`;

function entitySearchQuery(
    apiHost: string,
    language: string,
    itemIri: string,
    propertyIri: string,
    type: 'item' | 'property',
): string {
    // Properties are searched as entities (…/entity/P31) but used as direct
    // claims (…/prop/direct/P31), so the IRI has to be rewritten.
    const entityBinding = type === 'property'
        ? `BIND(IRI(CONCAT("${propertyIri}", STRAFTER(STR(?qls_match), "${itemIri}"))) AS ?qls_entity)`
        : `BIND(?qls_match AS ?qls_entity)`;

    return `${WIKIBASE_PREFIXES}
{% if search_term %}
SELECT ?qls_entity ?qls_label ?qls_description WHERE {
  SERVICE wikibase:mwapi {
    bd:serviceParam wikibase:api "EntitySearch" .
    bd:serviceParam wikibase:endpoint "${apiHost}" .
    bd:serviceParam mwapi:search "{{ search_term }}" .
    bd:serviceParam mwapi:language "${language}" .
    bd:serviceParam mwapi:type "${type}" .
    ?qls_match wikibase:apiOutputItem mwapi:item .
  }
  ${entityBinding}
  OPTIONAL { ?qls_match rdfs:label ?qls_label . FILTER(LANG(?qls_label) = "${language}") }
  OPTIONAL { ?qls_match schema:description ?qls_description . FILTER(LANG(?qls_description) = "${language}") }
}
LIMIT {{ limit }}
{% else %}
SELECT ?qls_entity WHERE { ?qls_entity ?qls_p ?qls_o } LIMIT 0
{% endif %}`;
}

function hoverQuery(language: string, itemIri: string, propertyIri: string): string {
    return `${WIKIBASE_PREFIXES}
SELECT ?qls_label ?qls_alias WHERE {
  BIND({{ entity }} AS ?qls_iri)
  BIND(IF(STRSTARTS(STR(?qls_iri), "${propertyIri}"),
          IRI(CONCAT("${itemIri}", STRAFTER(STR(?qls_iri), "${propertyIri}"))),
          ?qls_iri) AS ?qls_subject)
  OPTIONAL { ?qls_subject rdfs:label ?qls_label . FILTER(LANG(?qls_label) = "${language}") }
  OPTIONAL { ?qls_subject schema:description ?qls_alias . FILTER(LANG(?qls_alias) = "${language}") }
}
LIMIT 1`;
}
