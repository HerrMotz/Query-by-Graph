import {WikibaseDataSource} from "./WikibaseDataSource";

export interface EntityType {
    id: string,
    label: string,
    description: string,
    prefix: PrefixType,
    dataSource: WikibaseDataSource;
    selectedForProjection?: boolean;
    distinct?: boolean;
    isLiteral?: boolean;
}

export interface PrefixType {
    iri: string,
    abbreviation: string,
}