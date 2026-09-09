import * as monaco from "monaco-editor";

// Monaco ships no SPARQL language. The editor in App.vue asks for
// `language="sparql"`, so it has to be registered before the editor mounts —
// otherwise the query is rendered as plain text and the language server
// providers (which are keyed by language id) are never asked.

const KEYWORDS = [
    'SELECT', 'CONSTRUCT', 'DESCRIBE', 'ASK',
    'WHERE', 'FROM', 'NAMED', 'OPTIONAL', 'UNION', 'GRAPH',
    'FILTER', 'BIND', 'HAVING', 'GROUP', 'ORDER', 'BY', 'LIMIT', 'OFFSET',
    'ASC', 'DESC', 'DISTINCT', 'REDUCED',
    'PREFIX', 'BASE', 'INSERT', 'DELETE', 'WITH', 'USING',
    'CLEAR', 'DROP', 'CREATE', 'ADD', 'MOVE', 'COPY', 'LOAD',
    'DEFAULT', 'ALL', 'INTO', 'VALUES', 'UNDEF',
    'MINUS', 'SERVICE', 'SILENT', 'AS', 'NOT', 'IN', 'EXISTS',
];

const BUILTINS = [
    'STR', 'LANG', 'LANGMATCHES', 'DATATYPE', 'BOUND', 'IRI', 'URI', 'BNODE',
    'RAND', 'ABS', 'CEIL', 'FLOOR', 'ROUND', 'CONCAT', 'STRLEN', 'UCASE', 'LCASE',
    'ENCODE_FOR_URI', 'CONTAINS', 'STRSTARTS', 'STRENDS', 'STRBEFORE', 'STRAFTER',
    'YEAR', 'MONTH', 'DAY', 'HOURS', 'MINUTES', 'SECONDS', 'TIMEZONE', 'TZ', 'NOW',
    'UUID', 'STRUUID', 'MD5', 'SHA1', 'SHA256', 'SHA384', 'SHA512',
    'COALESCE', 'IF', 'STRLANG', 'STRDT', 'SAMETERM',
    'ISIRI', 'ISURI', 'ISBLANK', 'ISLITERAL', 'ISNUMERIC',
    'REGEX', 'SUBSTR', 'REPLACE',
    'COUNT', 'SUM', 'MIN', 'MAX', 'AVG', 'SAMPLE', 'GROUP_CONCAT',
];

export function registerSparqlLanguage() {
    if (monaco.languages.getLanguages().some(language => language.id === 'sparql')) return;

    monaco.languages.register({id: 'sparql', extensions: ['.rq', '.sparql']});

    monaco.languages.setLanguageConfiguration('sparql', {
        comments: {lineComment: '#'},
        brackets: [['{', '}'], ['(', ')'], ['[', ']']],
        autoClosingPairs: [
            {open: '{', close: '}'},
            {open: '(', close: ')'},
            {open: '[', close: ']'},
            {open: '"', close: '"', notIn: ['string']},
            {open: "'", close: "'", notIn: ['string']},
            {open: '<', close: '>'},
        ],
    });

    monaco.languages.setMonarchTokensProvider('sparql', {
        ignoreCase: true,
        keywords: KEYWORDS,
        builtins: BUILTINS,
        tokenizer: {
            root: [
                [/#[^\r\n]*/, 'comment'],
                [/"""/, 'string', '@longStringDouble'],
                [/'''/, 'string', '@longStringSingle'],
                [/"([^"\\]|\\.)*"/, 'string'],
                [/'([^'\\]|\\.)*'/, 'string'],
                [/<[^\s>]*>/, 'type'],
                [/_:[a-zA-Z0-9_]+/, 'variable.predefined'],
                [/[?$][a-zA-Z_][a-zA-Z0-9_]*/, 'variable'],
                [/[a-zA-Z_][a-zA-Z0-9_.%-]*:/, 'namespace'],
                [/[a-zA-Z_][a-zA-Z0-9_]*/, {
                    cases: {
                        '@keywords': 'keyword',
                        '@builtins': 'predefined',
                        '@default': 'identifier',
                    },
                }],
                [/[+-]?\d*\.\d+([eE][+-]?\d+)?/, 'number.float'],
                [/[+-]?\d+/, 'number'],
                [/[{}()[\]]/, '@brackets'],
                [/[;,.]/, 'delimiter'],
                [/\^\^|&&|\|\||[!<>=+\-*/]/, 'operator'],
            ],
            longStringDouble: [
                [/"""/, 'string', '@pop'],
                [/[^"]+/, 'string'],
                [/"/, 'string'],
            ],
            longStringSingle: [
                [/'''/, 'string', '@pop'],
                [/[^']+/, 'string'],
                [/'/, 'string'],
            ],
        },
    } as monaco.languages.IMonarchLanguage);
}
