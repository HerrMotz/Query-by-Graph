import {EntityType} from "./EntityType.ts";

interface ConnectionInterfaceType {
  property: EntityType,
  source: EntityType,
  target: EntityType
}

export default ConnectionInterfaceType;
