import type {EntityType} from "../types/EntityType.ts";
import type {WikibaseDataSource} from "../types/WikibaseDataSource.ts";

export function rdfPrefixes(source: WikibaseDataSource): Record<string, string> {
    return {
        ...source.prefixMap,
        [source.itemPrefix.abbreviation]: source.itemPrefix.iri,
        [source.propertyPrefix.abbreviation]: source.propertyPrefix.iri
    };
}

export function rdfEntity(source: WikibaseDataSource, id: string, label = id): EntityType | undefined {
    const prefixes = rdfPrefixes(source);
    const colon = id.indexOf(':');
    const abbreviation = id.slice(0, colon);
    if (colon > 0 && prefixes[abbreviation] && /^[A-Za-z0-9_%.-]+$/.test(id.slice(colon + 1))) {
        return {
            id: id.slice(colon + 1), label, description: '', dataSource: source,
            prefix: {iri: prefixes[abbreviation], abbreviation}
        };
    }
    const iri = id.replace(/^<|>$/g, '');
    // Accept explicit HTTP(S) IRIs; do not interpret unverified names as ids.
    if (!/^https?:\/\/[^\s<>"{}|^`\\]+$/.test(iri)) return undefined;
    const prefix = Object.entries(prefixes).find(([, namespace]) => iri.startsWith(namespace));
    if (prefix && /^[A-Za-z0-9_%.-]+$/.test(iri.slice(prefix[1].length))) {
        return {
            id: iri.slice(prefix[1].length), label, description: '', dataSource: source,
            prefix: {iri: prefix[1], abbreviation: prefix[0]}
        };
    }
    return {id: `<${iri}>`, label, description: '', dataSource: source, prefix: {iri: '', abbreviation: ''}};
}

export function searchRdfVocabulary(source: WikibaseDataSource, query: string, type: string): EntityType[] {
    const term = query.trim();
    const matches = (source.vocabulary ?? [])
        .filter(entry => entry.type === type && `${entry.id} ${entry.label}`.toLowerCase().includes(term.toLowerCase()))
        .map(entry => rdfEntity(source, entry.id, entry.label)!);
    const explicit = rdfEntity(source, term);
    if (explicit && !matches.some(entity => entity.id === explicit.id && entity.prefix.iri === explicit.prefix.iri)) {
        matches.unshift(explicit);
    }
    return matches;
}

export function queryUrl(source: WikibaseDataSource, query: string): string {
    if (source.kind !== 'sparql') return source.queryService + '#' + encodeURIComponent(query);
    const url = new URL(source.sparqlEndpoint ?? source.queryService);
    url.searchParams.set('query', query);
    return url.toString();
}
