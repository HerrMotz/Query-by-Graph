import {EntityType} from "./EntityType.ts";

interface ConnectionInterfaceType {
  properties: EntityType[],
  source: EntityType,
  target: EntityType
}

export default ConnectionInterfaceType;
