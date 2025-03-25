import {Ref, ref} from 'vue';
import {WikibaseDataSource} from "./lib/types/WikibaseDataSource.ts";
import {factGridDataSource, mimoDataSource, wikiDataDataSource} from "./lib/constants";

export const defaultDataSources = [
    wikiDataDataSource,
    factGridDataSource,
    mimoDataSource
];

export const selectedDataSource = ref<WikibaseDataSource>(wikiDataDataSource);


// initialize the data sources from local storage on page load
const localstorageDataSourcesKey = 'dataSources';
const storedDataSources = localStorage.getItem(localstorageDataSourcesKey);
// add the new data source to the list
const localStoreDataSources = storedDataSources ? JSON.parse(storedDataSources) : defaultDataSources;

export const dataSources = ref<WikibaseDataSource[]>(localStoreDataSources);

export const resetDataSourceToDefault = () => {
    dataSources.value = defaultDataSources;
    selectedDataSource.value = defaultDataSources[0];
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