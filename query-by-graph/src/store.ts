import { ref } from 'vue';
import {WikibaseDataSource} from "./lib/types/WikibaseDataSource.ts";
import {factGridDataSource, wikiDataDataSource} from "./lib/constants";


export const selectedDataSource = ref<WikibaseDataSource>(wikiDataDataSource);
export const dataSources = [
        wikiDataDataSource,
        factGridDataSource,
];