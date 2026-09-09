import {EntityType} from "../types/EntityType.ts";
import {noDataSource} from "../constants";
import {deepCopy} from "../utils";

const variableEntity: EntityType = { // EntityType
    id: '?',
    label: 'Variable',
    description: 'Variable Entity',
    prefix: {
        iri: "",
        abbreviation: "",
    },
    dataSource: noDataSource,
    selectedForProjection: true,
    distinct: false
};

const variableEntityConstructor = (name: string): EntityType => {
    const newVariable = deepCopy(variableEntity);
    newVariable.id = "?"+name;
    return newVariable;
}

const noEntity: EntityType = {
    id: '',
    label: '',
    description: '',
    prefix: {
        iri: "",
        abbreviation: "",
    },
    dataSource: noDataSource,
    selectedForProjection: false
};

/**
 * Infer the XSD datatype of a raw string value and return the SPARQL literal representation.
 * - Integer: "42"^^xsd:integer
 * - Decimal: "3.14"^^xsd:decimal
 * - Date (YYYY-MM-DD): "2024-01-01T00:00:00Z"^^xsd:dateTime  (Wikibase convention: dates are stored as dateTime)
 * - DateTime (ISO 8601): "2024-01-01T00:00:00"^^xsd:dateTime
 * - Boolean: "true"^^xsd:boolean
 * - Default: "hello"^^xsd:string
 */
function inferXsdLiteral(rawValue: string): { sparqlLiteral: string; xsdType: string } {
    const trimmed = rawValue.trim();

    // Boolean
    if (trimmed === 'true' || trimmed === 'false') {
        return { sparqlLiteral: `"${trimmed}"^^xsd:boolean`, xsdType: 'boolean' };
    }

    // Integer (no decimal point, optional leading minus)
    if (/^-?\d+$/.test(trimmed)) {
        return { sparqlLiteral: `"${trimmed}"^^xsd:integer`, xsdType: 'integer' };
    }

    // Decimal (has decimal point, optional leading minus)
    if (/^-?\d+\.\d+$/.test(trimmed)) {
        return { sparqlLiteral: `"${trimmed}"^^xsd:decimal`, xsdType: 'decimal' };
    }

    // DateTime (ISO 8601 with time component)
    if (/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(:\d{2})?(\.\d+)?(Z|[+-]\d{2}:\d{2})?$/.test(trimmed)) {
        const d = new Date(trimmed);
        if (!isNaN(d.getTime())) {
            return { sparqlLiteral: `"${trimmed}"^^xsd:dateTime`, xsdType: 'dateTime' };
        }
    }

    // Date (YYYY-MM-DD)
    // Wikibase convention: dates are stored as xsd:dateTime, not xsd:date.
    // A plain date is expanded to midnight UTC to conform to this convention.
    if (/^\d{4}-\d{2}-\d{2}$/.test(trimmed)) {
        const d = new Date(trimmed);
        if (!isNaN(d.getTime())) {
            return { sparqlLiteral: `"${trimmed}T00:00:00Z"^^xsd:dateTime`, xsdType: 'dateTime' };
        }
    }

    // Default: string
    return { sparqlLiteral: `"${trimmed}"^^xsd:string`, xsdType: 'string' };
}

/**
 * Create a literal EntityType from a raw value string (the part inside the quotes).
 * The entity id will be the full SPARQL literal, e.g. "42"^^xsd:integer.
 */
function literalEntityConstructor(rawValue: string): EntityType {
    const { sparqlLiteral, xsdType } = inferXsdLiteral(rawValue);
    return {
        id: sparqlLiteral,
        label: `"${rawValue}"`,
        description: `Literal value (xsd:${xsdType})`,
        prefix: {
            iri: "",
            abbreviation: "",
        },
        dataSource: noDataSource,
        selectedForProjection: false,
        isLiteral: true,
    };
}

export {noEntity, variableEntity, variableEntityConstructor, literalEntityConstructor, inferXsdLiteral}

