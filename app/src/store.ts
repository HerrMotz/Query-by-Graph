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

// This module runs at import time, so a corrupted localStorage entry would
// otherwise throw before the app ever mounts. Fall back to the defaults instead.
const readStored = <T>(key: string, isValid: (value: any) => boolean, fallback: T): T => {
    const stored = localStorage.getItem(key);
    if (stored === null) return fallback;

    try {
        const parsed = JSON.parse(stored);
        return isValid(parsed) ? parsed as T : fallback;
    } catch {
        console.warn(`Discarding malformed localStorage entry '${key}'.`);
        return fallback;
    }
}

const isDataSource = (value: any): boolean =>
    !!value && typeof value === 'object' && !Array.isArray(value);

const localstorageSelectedDataSourceKey = 'selectedDataSource';
export const selectedDataSource = ref<WikibaseDataSource>(
    backfillFromDefaults(readStored(localstorageSelectedDataSourceKey, isDataSource, wikiDataDataSource))
);
// The backfill has to reach local storage as well, which is not reactive.
localStorage.setItem(localstorageSelectedDataSourceKey, JSON.stringify(selectedDataSource.value));


// initialize the data sources from local storage on page load
const localstorageDataSourcesKey = 'dataSources';
const localStoreDataSources = readStored<WikibaseDataSource[]>(
    localstorageDataSourcesKey,
    // An empty list would leave the app with no source to select.
    (value) => Array.isArray(value) && value.length > 0 && value.every(isDataSource),
    defaultDataSources
).map(backfillFromDefaults);
localStorage.setItem(localstorageDataSourcesKey, JSON.stringify(localStoreDataSources));

export const dataSources = ref<WikibaseDataSource[]>(localStoreDataSources);

export const setSelectedDataSource = (source: WikibaseDataSource) => {
    selectedDataSource.value = source;
    localStorage.setItem(localstorageSelectedDataSourceKey, JSON.stringify(source));
}

export const resetDataSourceToDefault = () => {
    // Copy, so later additions don't mutate the shared defaults array.
    dataSources.value = [...defaultDataSources];
    setSelectedDataSource(defaultDataSources[0]);
    localStorage.setItem(localstorageDataSourcesKey, JSON.stringify(defaultDataSources));
}

export const addDataSourceToStorage = (dataSources: Ref<WikibaseDataSource[]>, source: WikibaseDataSource) => {
    // The local storage is non-reactive. Therefore, it needs to be stored in a ref
    //  and also in the local storage.

    dataSources.value.push(source);

    // load the local storage data sources
    const localStoreDataSources = readStored<WikibaseDataSource[]>(
        localstorageDataSourcesKey,
        (value) => Array.isArray(value),
        []
    );
    // add the new data source to the list
    localStoreDataSources.push(source);
    // write the data sources back to local storage
    localStorage.setItem(localstorageDataSourcesKey, JSON.stringify(localStoreDataSources));
}

export const deleteDataSourceFromStorage = (index: number) => {
    dataSources.value.splice(index, 1);

    // Deleting the last source would otherwise leave `selectedDataSource`
    // undefined, which every consumer of the prefixes then chokes on.
    if (dataSources.value.length === 0) {
        resetDataSourceToDefault();
        return;
    }

    setSelectedDataSource(dataSources.value[0]);
    localStorage.setItem(localstorageDataSourcesKey, JSON.stringify(dataSources.value));
}