function hljsDefineSparql(hljs: any) {
    return {
        case_insensitive: true,
        keywords: {
            keyword: 'BASE PREFIX SELECT CONSTRUCT ASK DESCRIBE WHERE ORDER BY ASC DESC LIMIT OFFSET ' +
                'FILTER OPTIONAL GRAPH UNION BIND VALUES MINUS SERVICE DISTINCT REDUCED FROM NAMED ' +
                'AS GROUP HAVING AVG COUNT SUM MIN MAX SAMPLE GROUP_CONCAT SEPARATOR NOW YEAR ' +
                'MONTH DAY HOURS MINUTES SECONDS TIMEZONE TZ MD5 SHA1 SHA256 SHA384 SHA512 ' +
                'COALESCE IF STRLANG STRDT SAMETERM ISIRI ISURI ISBLANK ISLITERAL ISNUMERIC ' +
                'STRUUID UUID STRLEN STR SUBSTR UCASE LCASE STRSTARTS STRENDS CONTAINS STRAFTER ' +
                'STRBEFORE ENCODE_FOR_URI CONCAT REPLACE ABS ROUND CEIL FLOOR RAND ' +
                'SIN COS TAN ASIN ACOS ATAN1 ATAN2 EXP LOG10 LOG2 LN POW SQRT ' +
                'EXISTS NOT EXISTS BINDINGS',
            literal: 'true false',
            built_in: 'a'
        },
        contains: [
            hljs.COMMENT('#', '$'),
            {
                className: 'string',
                variants: [
                    {begin: /"""/, end: /"""/},
                    {begin: /"/, end: /"/},
                    {begin: /'''/, end: /'''/},
                    {begin: /'/, end: /'/}
                ]
            },
            {
                className: 'number',
                variants: [
                    {begin: '\\b\\d+(\\.\\d+)?(E[+-]?\\d+)?\\b'}
                ]
            },
            {
                className: 'variable',
                begin: '\\?[a-zA-Z_][a-zA-Z0-9_]*'
            },
            {
                className: 'variable',
                begin: '\\$[a-zA-Z_][a-zA-Z0-9_]*'
            },
            {
                className: 'keyword',
                begin: '\\ba\\b'
            },
            {
                className: 'meta',
                begin: '<', end: '>'
            },
            {
                className: 'symbol',
                begin: '[{}\\[\\]()\\.,;]'
            },
            {
                className: 'operator',
                begin: /(\^\^|[~!@#%\^&*+=|?:<>/-])/,
                relevance: 0
            }
        ]
    };
}
export default hljsDefineSparql