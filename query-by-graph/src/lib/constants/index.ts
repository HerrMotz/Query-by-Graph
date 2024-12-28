import {WikibaseDataSource} from "../types/WikibaseDataSource.ts";

const wikiDataDataSource: WikibaseDataSource = {
    name: "WikiData",
    uri: "https://www.wikidata.org/w/api.php",
    preferredLanguages: ['en'],
    itemPrefix: {
        iri: "http://www.wikidata.org/entity/",
        abbreviation: "wd"
    },
    propertyPrefix: {
        iri: "http://www.wikidata.org/prop/direct/",
        abbreviation: "wdt"
    },
    queryService: "https://query.wikidata.org/", // do not leave blank spaces in urls
}

const factGridDataSource: WikibaseDataSource = {
    name: "FactGrid",
    uri: "https://database.factgrid.de/w/api.php",
    preferredLanguages: ['de'],
    itemPrefix: {
        iri: "https://database.factgrid.de/entity/",
        abbreviation: "fg"
    },
    propertyPrefix: {
        iri: "https://database.factgrid.de/prop/direct/",
        abbreviation: "fgt"
    },
    queryService: "https://database.factgrid.de/query/",
}

const testinstanceSource: WikibaseDataSource = {
    name: "Test Instance",
    uri: "https://daniels-test-instance.wikibase.cloud/",
    preferredLanguages: ['en'],
    itemPrefix: {
        iri: "https://daniels-test-instance.wikibase.cloud/entity/",
        abbreviation: "ti"
    },
    propertyPrefix: {
        iri: "https://daniels-test-instance.wikibase.cloud/prop/direct/",
        abbreviation: "tt"
    },
    queryService: "https://daniels-test-instance.wikibase.cloud/query/",
}

const noDataSource: WikibaseDataSource = {
    name: "",
    uri: "",
    preferredLanguages: [],
    propertyPrefix: {
        iri: "",
        abbreviation: ""
    },
    itemPrefix: {
        iri: "",
        abbreviation: ""
    },
    queryService: "",
}

export {wikiDataDataSource,factGridDataSource,testinstanceSource,noDataSource}