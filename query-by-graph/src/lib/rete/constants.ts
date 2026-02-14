import {EntityType} from "../types/EntityType.ts";
import {noDataSource} from "../constants";
import {deepCopy} from "../utils";

const variableEntity: EntityType = { // EntityType
    id: '?',
    label: 'Variable',
    description: 'Variable Entity',
    prefix: {
        iri: "",
        abbreviation: "",
    },
    dataSource: noDataSource,
    selectedForProjection: true
};

const variableEntityConstructor = (name: string): EntityType => {
    const newVariable = deepCopy(variableEntity);
    newVariable.id = "?"+name;
    return newVariable;
}

const noEntity: EntityType = {
    id: '',
    label: '',
    description: '',
    prefix: {
        iri: "",
        abbreviation: "",
    },
    dataSource: noDataSource,
    selectedForProjection: false
};

export {noEntity, variableEntity, variableEntityConstructor}