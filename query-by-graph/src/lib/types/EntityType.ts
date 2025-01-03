import {WikibaseDataSource} from "./WikibaseDataSource";

interface EntityType {
    id: string,
    label: string,
    description: string,
    prefix: {
       iri: string,
       abbreviation: string,
    };
    dataSource: WikibaseDataSource;
}

export default EntityType;
