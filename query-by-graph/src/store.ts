import {Ref, ref} from 'vue';
import {WikibaseDataSource} from "./lib/types/WikibaseDataSource.ts";
import {factGridDataSource, mimoDataSource, wikiDataDataSource} from "./lib/constants";

// Global DISTINCT setting – when true every variable node is marked as distinct
export const globalDistinct = ref<boolean>(false);

export const defaultDataSources = [
    wikiDataDataSource,
    factGridDataSource,
    mimoDataSource
];

const localstorageSelectedDataSourceKey = 'selectedDataSource';
const storedSelectedDataSource = localStorage.getItem(localstorageSelectedDataSourceKey);
export const selectedDataSource = ref<WikibaseDataSource>(
    storedSelectedDataSource ? JSON.parse(storedSelectedDataSource) : wikiDataDataSource
);


// initialize the data sources from local storage on page load
const localstorageDataSourcesKey = 'dataSources';
const storedDataSources = localStorage.getItem(localstorageDataSourcesKey);
if (!storedDataSources) {
    localStorage.setItem(localstorageDataSourcesKey, JSON.stringify(defaultDataSources));
}
// add the new data source to the list
const localStoreDataSources = storedDataSources ? JSON.parse(storedDataSources) : defaultDataSources;

export const dataSources = ref<WikibaseDataSource[]>(localStoreDataSources);

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