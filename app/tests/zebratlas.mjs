import {test} from 'node:test';
import assert from 'node:assert/strict';
import {zebratlasDataSource as source} from '../src/lib/constants/zebratlas.ts';
import {rdfEntity, searchRdfVocabulary, queryUrl} from '../src/lib/utils/rdfVocabulary.ts';
import {backendFromDataSource} from '../src/lib/monaco/sparqlBackend.ts';

test('RDF selectors resolve verified labels, classes, prefixed ids and full IRIs', () => {
    const gene = searchRdfVocabulary(source, 'STXBP1', 'item')[0];
    assert.equal(gene.id, 'HGNC%3A11444');
    assert.equal(gene.prefix.abbreviation, 'raid');
    assert.equal(searchRdfVocabulary(source, 'associated', 'property')[0].id, 'has_associated_gene');
    assert.equal(searchRdfVocabulary(source, 'ra:Node', 'item')[0].prefix.abbreviation, 'ra');
    assert.deepEqual(searchRdfVocabulary(source, 'unverified disease name', 'item'), []);
    assert.equal(rdfEntity(source, '<https://w3id.org/rare-disease-atlas/id/HGNC%3A11444>').id, gene.id);
    assert.equal(rdfEntity(source, 'https://example.org/entity/123').id, '<https://example.org/entity/123>');
    assert.equal(rdfEntity(source, 'javascript:alert(1)'), undefined);
    assert.equal(rdfEntity(source, 'ra:Node } UNION { ?s ?p ?o'), undefined);
});

test('Run uses a SPARQL GET query parameter and preserves Wikibase query URLs', () => {
    const query = 'SELECT ?s WHERE { ?s ?p "a&b#c" } LIMIT 5';
    const url = new URL(queryUrl(source, query));
    assert.equal(url.origin + url.pathname, source.sparqlEndpoint);
    assert.equal(url.searchParams.get('query'), query);
    assert.equal(url.hash, '');
    const wikibase = {...source, kind: undefined, queryService: 'https://query.wikidata.org/'};
    assert.equal(queryUrl(wikibase, query), wikibase.queryService + '#' + encodeURIComponent(query));
});

test('RDF language server uses standard bounded templates and all prefixes', () => {
    const backend = backendFromDataSource(source);
    assert.equal(backend.url, source.sparqlEndpoint);
    assert.equal(backend.engine, undefined);
    assert.equal(backend.requestMethod, 'GET');
    assert.equal(backend.prefixMap.raid, source.itemPrefix.iri);
    assert.equal(backend.prefixMap.prov, 'http://www.w3.org/ns/prov#');
    for (const [type, query] of Object.entries(backend.queries)) {
        assert.doesNotMatch(query, /wikibase:|mwapi:|Blazegraph/);
        assert.match(query, /LIMIT/);
        if (type !== 'hover') assert.match(query, /VALUES/);
    }
    const wikibase = {...source, kind: undefined, uri: 'https://www.wikidata.org/w/api.php'};
    assert.equal(backendFromDataSource(wikibase).engine, 'Blazegraph');
    assert.match(backendFromDataSource(wikibase).queries.subjectCompletion, /SERVICE wikibase:mwapi/);
});
