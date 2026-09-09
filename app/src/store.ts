import {Ref, ref} from 'vue';
import {WikibaseDataSource} from "./lib/types/WikibaseDataSource.ts";
import {factGridDataSource, mimoDataSource, wikiDataDataSource} from "./lib/constants";

export const defaultDataSources = [
    wikiDataDataSource,
    factGridDataSource,
    mimoDataSource
];

/**
 * Data sources are persisted in local storage, so the ones stored by an earlier
 * version of the app lack fields that were added later — currently
 * `sparqlEndpoint`, without which the language server queries the wrong URL.
 * Take those over from the default data source they were copied from.
 */
const backfillFromDefaults = (source: WikibaseDataSource): WikibaseDataSource => {
    if (source.sparqlEndpoint) return source;
    const original = defaultDataSources.find(
        candidate => candidate.name === source.name || candidate.uri === source.uri
    );
    return original?.sparqlEndpoint ? {...source, sparqlEndpoint: original.sparqlEndpoint} : source;
};

const localstorageSelectedDataSourceKey = 'selectedDataSource';
const storedSelectedDataSource = localStorage.getItem(localstorageSelectedDataSourceKey);
export const selectedDataSource = ref<WikibaseDataSource>(
    storedSelectedDataSource ? backfillFromDefaults(JSON.parse(storedSelectedDataSource)) : wikiDataDataSource
);


// initialize the data sources from local storage on page load
const localstorageDataSourcesKey = 'dataSources';
const storedDataSources = localStorage.getItem(localstorageDataSourcesKey);
if (!storedDataSources) {
    localStorage.setItem(localstorageDataSourcesKey, JSON.stringify(defaultDataSources));
}
// add the new data source to the list
const localStoreDataSources: WikibaseDataSource[] = storedDataSources
    ? JSON.parse(storedDataSources).map(backfillFromDefaults)
    : defaultDataSources;

export const dataSources = ref<WikibaseDataSource[]>(localStoreDataSources);

// The backfill has to reach local storage as well, which is not reactive.
if (storedDataSources) localStorage.setItem(localstorageDataSourcesKey, JSON.stringify(localStoreDataSources));
if (storedSelectedDataSource) {
    localStorage.setItem(localstorageSelectedDataSourceKey, JSON.stringify(selectedDataSource.value));
}

export const setSelectedDataSource = (source: WikibaseDataSource) => {
    selectedDataSource.value = source;
    localStorage.setItem(localstorageSelectedDataSourceKey, JSON.stringify(source));
}

export const resetDataSourceToDefault = () => {
    dataSources.value = defaultDataSources;
    setSelectedDataSource(defaultDataSources[0]);
    localStorage.setItem(localstorageDataSourcesKey, JSON.stringify(defaultDataSources));
}

export const addDataSourceToStorage = (dataSources: Ref<WikibaseDataSource[]>, source: WikibaseDataSource) => {
    // The local storage is non-reactive. Therefore, it needs to be stored in a ref
    //  and also in the local storage.

    dataSources.value.push(source);

    // load the local storage data sources
    const storedDataSources = localStorage.getItem(localstorageDataSourcesKey);
    // add the new data source to the list
    const localStoreDataSources = storedDataSources ? JSON.parse(storedDataSources) : [];
    localStoreDataSources.push(source);
    // write the data sources back to local storage
    localStorage.setItem(localstorageDataSourcesKey, JSON.stringify(localStoreDataSources));
}

export const deleteDataSourceFromStorage = (index: number) => {
    dataSources.value.splice(index, 1);
    selectedDataSource.value = dataSources.value[0];
    localStorage.setItem(localstorageDataSourcesKey, JSON.stringify(dataSources.value));
}