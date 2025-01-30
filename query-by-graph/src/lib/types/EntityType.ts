import {WikibaseDataSource} from "./WikibaseDataSource";

export interface EntityType {
    id: string,
    label: string,
    description: string,
    prefix: PrefixType,
    dataSource: WikibaseDataSource;
}

export interface PrefixType {
    iri: string,
    abbreviation: string,
}