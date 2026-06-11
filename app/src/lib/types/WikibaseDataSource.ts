import {PrefixType} from "./EntityType.ts";

export interface WikibaseDataSource {
    name: string;
    uri: string,
    preferredLanguages: string[],
    propertyPrefix: {
        iri: string,
        abbreviation: string
    },
    itemPrefix: PrefixType,
    queryService: string,
}

export type WikiDataEntity = {
    id: string;
    title: string;
    pageid: number;
    datatype: string;
    concepturi: string;
    repository: string;
    url: string; // for the api
    display: {
        label: {
            value: string;
            language: string;
        };
        description: {
            value: string;
            language: string;
        };
    };
    label: string;
    description: string;
    match: {
        type: string;
        language: string;
        text: string;
    };
    aliases?: string[];
};

export type WikiDataSearchApiResponse = {
    errors: string[];
    searchinfo: object;
    search: WikiDataEntity[];
    success: number;
};

export interface LanguageTaggedLiteral {
    language: string;
    value: string;
}

export interface WikiDataEntityDetails {
    id: string;
    labels: { [language: string]: LanguageTaggedLiteral };
    descriptions: { [language: string]: LanguageTaggedLiteral };
    claims: { [key: string]: any[] };
    image?: string | null;
}

export interface WikiDataResponse {
    entities: { [key: string]: WikiDataEntityDetails };
}
