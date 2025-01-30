import {ClassicPreset, GetSchemes, NodeEditor} from "rete";
import {Area2D, AreaExtensions, AreaPlugin} from "rete-area-plugin";
import {ConnectionPlugin, Presets as ConnectionPresets} from "rete-connection-plugin";
import {ConnectionPathPlugin} from "rete-connection-path-plugin";
import {HistoryExtensions, HistoryPlugin, Presets as HistoryPresets} from "rete-history-plugin";
import {Presets, VueArea2D, VuePlugin} from "rete-vue-plugin";
import {ArrangeAppliers, AutoArrangePlugin, Presets as ArrangePresets} from "rete-auto-arrange-plugin";
import {h} from "vue";
import CustomConnection from "../../components/PropertyConnection.vue";
import {removeNodeWithConnections} from "./utils.ts";
import {EntityType} from "../types/EntityType.ts";
import ConnectionInterfaceType from "../types/ConnectionInterfaceType.ts";
import EntityNodeComponent from "../../components/EntityNode.vue";
import CustomInputControl from "../../components/EntitySelectorInputControl.vue";
import {noEntity, variableEntityConstructor} from "./constants.ts";
import {noDataSource} from "../constants";
import {dataSources} from "../../store.ts";
import {LanguageTaggedLiteral, WikibaseDataSource} from "../types/WikibaseDataSource.ts";
import WikibaseDataService from "../wikidata/WikibaseDataService.ts";

function exportConnectionsHelper(editor:any) {
    return editor.getConnections().map((connection:any) => {
        const c = editor.getConnection(connection.id)
        const source = editor.getNode(c.source);
        const target = editor.getNode(c.target);
        return {
            property: c.property || noEntity,
            source: source.entity,
            target: target.entity
        };
    })
}

const INPUT_SOCKET_NAME = "i0";
const OUTPUT_SOCKET_NAME = "o0";

const fqdnRegex = new RegExp(/(?:[\w-]+\.)+[\w-]+/);

function convertConnectionsToPrefixedRepresentation(connections: Array<ConnectionInterfaceType>, vqgEntities: Array<EntityType>): Promise<ConnectionInterfaceType>[] {
    // this function takes in a connections array from e.g. the rust backend
    // and replaces the full URL with prefixes

    // if no prefix can be found, this means that the item is not from a data source the visual query builder knows
    // In this case, the prefix will not be replaced.

    return connections.map(connection => {
        const { property, source, target } = connection;

        function _replaceWithPrefix(entity:EntityType) {
            // check if it is a variable
            if (entity.id.startsWith('?')) {
                entity.label = 'Variable';
                return entity;
            }


            // find out, which data source the entity might belong to
            const fqdn = fqdnRegex.exec(entity.id);
            if (!fqdn || !fqdn[0]) {
                return entity;
            }

            async function _wikibase_metadata_helper(entity: EntityType, newIdentifier: string, datasource: WikibaseDataSource, rightPrefix: {iri: string, abbreviation: string}): Promise<EntityType | false> {
                // queries the wikidata api
                // returns false if no match could be found
                // else it will return an enriched entity
                const wds = new WikibaseDataService(datasource);

                function _findTheRightTranslation(preferredLanguages: string[], languageTaggedDict: { [language: string]: LanguageTaggedLiteral }) {
                    // This function takes the first found preferred language of the language tagged literal labels
                    // If the preferred language is not available, it will use English
                    // If English is not available, it will use the first available tagged literal.
                    return languageTaggedDict[preferredLanguages.find(lang => languageTaggedDict[lang].value) || 'en' || Object.keys(languageTaggedDict)[0]].value || "No literal found";
                }

                try {
                    const apiResult = await wds.getItemMetaInfo(newIdentifier);
                    if (apiResult) {
                        return {
                            ...entity,
                            id: newIdentifier,
                            label: _findTheRightTranslation(datasource.preferredLanguages, apiResult.labels),
                            description: _findTheRightTranslation(datasource.preferredLanguages, apiResult.descriptions),
                            prefix: rightPrefix,
                            dataSource: datasource,
                            // TODO add the remaining fields here (if you can think of any)
                        }
                    }
                    return entity;
                } catch (e) {
                    return {
                        ...entity,
                        id: newIdentifier
                    };
                }
            }

            function _vqg_metadata_helper(id: string, prefixIri: string, prefixAbbreviation: string): EntityType | false {
                // this function enriches the entity with metadata
                //  1. find a matching node in the VQG and make it equal
                //  2. if there is no node, fetch from the Wikidata API
                const foundMatch = vqgEntities.find((e: EntityType) => id === e.id && prefixIri === e.prefix.iri && prefixAbbreviation === e.prefix.abbreviation)
                // This conditional statement looks a bit sketch, because it does not cleanly differentiate between
                // edges and nodes. However, I can safely assume, that a node will not have a property prefix and vice
                // versa. In Wikibase, the id already is indicative of whether it is an item or a prop, but the prefixes
                // are important to differentiate between Wikibase instances.
                // In case the above explanation was unclear: This statement would match an edge with an item prefix and
                // Q-number as identifier. However, this "cannot" be the case, unless something is wrong in the Wikibase
                // instance data model. At this point, I just assume that it is.
                if (!foundMatch) {
                    return false;
                }

                return {...foundMatch} // TODO check whether this also work with pass by reference. Could save memory.
            }

            function _replace_helper(id: string, prefixIri: string) {
                return id.replace(prefixIri, "").replace("<", "").replace(">", "")
            }

            // TODO somehow it uses the property id with prefix but not this does not happen for itemprefix. Why? Ask someone else.
            //  I know why: because the _wrapper for properties is never called, as the item wrapper always returns something. This is devious.
            type ValidPrefixKeys = 'itemPrefix' | 'propertyPrefix';
            function _wrapper(fqdn: string, prefixKey: ValidPrefixKeys) {
                // this method is just a wrapper, because the code for items and props is identical, except for the
                // keys "itemPrefix" and "propertyPrefix"
                const matchingDatasourceForEntity = dataSources.find(s => s[prefixKey].iri.includes(fqdn));
                if (matchingDatasourceForEntity) {
                    const isTheRightPrefix = entity.id.includes(matchingDatasourceForEntity[prefixKey].iri);
                    // this part is very important! If it would not return false, the differentiation between prop and
                    //  item would not be correct.
                    if (!isTheRightPrefix) {
                        return false;
                    }
                    const newIdentifier = _replace_helper(entity.id, matchingDatasourceForEntity[prefixKey].iri)
                    const matchInVQG = _vqg_metadata_helper(newIdentifier, matchingDatasourceForEntity[prefixKey].iri, matchingDatasourceForEntity[prefixKey].abbreviation);
                    if (matchInVQG === false) {
                        // try to fetch from wikidata
                        return _wikibase_metadata_helper(entity, newIdentifier, matchingDatasourceForEntity, matchingDatasourceForEntity[prefixKey]).then(matchInWikibase => {
                            if (matchInWikibase === false) {
                                return {
                                    ...entity,
                                    id: newIdentifier,
                                    prefix: matchingDatasourceForEntity[prefixKey],
                                    dataSource: matchingDatasourceForEntity
                                }
                            } else {
                                return matchInWikibase;
                            }
                        });
                    } else {
                        return matchInVQG;
                    }
                } else {
                    return false;
                }

            }

            const item = _wrapper(fqdn[0], "itemPrefix")
            if (item) {
                return item
            }

            const property = _wrapper(fqdn[0], "propertyPrefix")
            if (property) {
                return property;
            }

            // return the entity from the input unchanged
            return entity;
        }

        return Promise.allSettled([
            _replaceWithPrefix(property),
            _replaceWithPrefix(source),
            _replaceWithPrefix(target)
        ]).then((values) => {
            if (
                values.every(
                    (result): result is PromiseFulfilledResult<EntityType> => result.status === "fulfilled"
                )
            ) {
                return {
                    property: (values[0] as PromiseFulfilledResult<EntityType>).value,
                    source: (values[1] as PromiseFulfilledResult<EntityType>).value,
                    target: (values[2] as PromiseFulfilledResult<EntityType>).value
                };
            } else {
                // this case will not occur, nevertheless typescript requires me to catch it.
                return {
                    property: noEntity,
                    source: noEntity,
                    target: noEntity
                };
            }
        });
    });
}


// Each connection holds additional data, which is defined here
class Connection<N extends ClassicPreset.Node> extends ClassicPreset.Connection<N, N> {
    selected?: boolean;
    property?: EntityType;
}

// Each node has to have "entity" metadata.
// This is ensured here.
class EntityNodeClass extends ClassicPreset.Node {
    entity: EntityType;
    width = 300; // this important for arranging the nodes
    height = 280;

    constructor(public label: string, public e: EntityType) {
        super(label);
        this.entity = e;
        console.log('EntityNodeClass constructor', this.entity);
    }

    setEntity(entity: EntityType) {
        console.log('setter called');
        this.entity = entity;
    }

    getEntity() {
        return this.entity;
    }
}

declare type InputControlOptions<N> = {
    /** Whether the control is readonly. Default is `false` */
    readonly?: boolean;
    /** Initial value of the control */
    initial?: N;
    /** Callback function that is called when the control value changes */
    change?: (value: N) => void;
};

class EntitySelectorInputControl extends ClassicPreset.InputControl<"text", EntityType> {
  constructor(public options: InputControlOptions<EntityType>) {
    super("text", options);
  }

}

type Schemes = GetSchemes<EntityNodeClass, Connection<EntityNodeClass>>;
type AreaExtra = VueArea2D<Schemes>;

function createNode(socket: ClassicPreset.Socket, highestIdCount: number, editor: any, area: any) {
    const newEntity = variableEntityConstructor(
        highestIdCount.toString()
    )

    const node = new EntityNodeClass(newEntity.label, newEntity);

    // DEBUG
    // console.log("Node", node.entity);

    node.addControl(
        "entityInput",
        new EntitySelectorInputControl({
            initial: {id: "", label: "", prefix: {iri: "", abbreviation: ""}, description: "", dataSource: noDataSource},
            change(value) {
                // DEBUG
                // console.log("Entity Input called change")
                // console.log(value)
                // console.log("node entity value")
                // console.log(node.getEntity())
                node.setEntity(value)
                // console.log("node value after update")
                // console.log(node.getEntity())

                editor.getConnections().forEach((c:any) => {
                    area.update("connection", c.id)
                })

                // console.log("update node in area")
                area.update("node", node.id)
            }
        })
    );
    node.addInput(INPUT_SOCKET_NAME, new ClassicPreset.Input(socket, "", true));
    node.addOutput(OUTPUT_SOCKET_NAME, new ClassicPreset.Output(socket, "", true));

    return node;
}

export async function createEditor(container: HTMLElement) {
    const socket = new ClassicPreset.Socket("socket");

    const editor = new NodeEditor<Schemes>();
    const area = new AreaPlugin<Schemes, AreaExtra>(container);
    const connection = new ConnectionPlugin<Schemes, AreaExtra>();
    const render = new VuePlugin<Schemes, AreaExtra>();
    const selector = AreaExtensions.selector();
    const accumulating = AreaExtensions.accumulateOnCtrl();
    const history = new HistoryPlugin<Schemes>();
    const arrange = new AutoArrangePlugin<Schemes>();

    let vueCallback: (context: any) => void;
    let highestIdCount = 0;
    let increaseVariablePropCounter = false;

    HistoryExtensions.keyboard(history);

    history.addPreset(HistoryPresets.classic.setup());

    function SelectableConnectionBind(props: { data: Schemes["Connection"] }) {
        const id = props.data.id;

        if (increaseVariablePropCounter) {
            increaseVariablePropCounter = false;
            highestIdCount++;
        }

        if (!props.data.property) {
            props.data.property = variableEntityConstructor(highestIdCount.toString())
        }

        const label = "connection";

        // Initialize the custom connection with the custom props
        // and connect it to our editor events
        return h(CustomConnection, {
            ...props, onClick: () => {
                // DEBUG
                // console.log("Selected connection", id)
                selector.add(
                    {
                        id,
                        label,
                        translate() {
                        },
                        unselect() {
                            props.data.selected = false;
                            area.update("connection", id);
                        }
                    },
                    accumulating.active()
                );
                props.data.selected = true;
                area.update("connection", id);
            },
            onChangedEntitySelector: (value: EntityType) => {
                // in order to force the editor to notice the change,
                // I need to create a copy of the connection,
                // change the entity and add it back.
                props.data.property = value;
                editor.getConnections().forEach((c) => {
                    area.update("connection", c.id)
                })
            },
        });
    }

    AreaExtensions.selectableNodes(area, selector, {
        accumulating: accumulating
    });

    render.addPreset(Presets.classic.setup({
        customize: {
            control(data) {
                // DEBUG
                // console.log("Control payload")
                // console.log(data.payload);
                if (data.payload instanceof EntitySelectorInputControl) {
                    return CustomInputControl;
                }
            },
            node(_) {
                // DEBUG
                // console.log("Node payload")
                // console.log(data.payload);
                return EntityNodeComponent;
            },
            connection() {
                return SelectableConnectionBind;
            }
        }
    }));

    async function _layout_helper(animate?: boolean) {
        console.log("Layout start");
        await arrange.layout({
            applier: animate ? applier : undefined,
            options: {
                'elk.spacing.nodeNode': "100",
                'elk.layered.spacing.nodeNodeBetweenLayers': "240"
            }
        });
        AreaExtensions.zoomAt(area, editor.getNodes());
    }

    const pathPlugin = new ConnectionPathPlugin<Schemes, Area2D<Schemes>>({
        arrow: () => true
    });

    // @ts-ignore
    render.use(pathPlugin);

    connection.addPreset(ConnectionPresets.classic.setup());

    area.addPipe(async (context) => {
        // this is a workaround to hinder the counter from increasing at every
        // draw method of the editor
        if (context.type === "connectioncreated") {
            increaseVariablePropCounter = true;
        }

        // This matches a Right Mouse button Click
        if (context.type === "contextmenu") {
            const source = context.data.context;
            const event = context.data.event;
            event.preventDefault();
            event.stopPropagation();

            // This method allows to add a new node with the Right Mouse Button click
            if (source === "root") { // add a new node
                // DEBUG
                console.log("Add variable node")

                highestIdCount++;

                const node = createNode(socket, highestIdCount, editor, area);

                await editor.addNode(node);

                area.area.setPointerFrom(event);

                await area.translate(node.id, area.area.pointer);

            } else if (source instanceof ClassicPreset.Node) { // remove existing node
                // DEBUG
                // console.log("Remove node", source.id);
                for (const c of editor
                    .getConnections()
                    .filter((c) => c.source === source.id || c.target === source.id)) {
                    await editor.removeConnection(c.id);
                }
                await editor.removeNode(source.id);
            }
        }

        if(context.type === 'nodepicked') {
            const node = context.data as ClassicPreset.Node;
            console.log(`Node clicked: ${node.id}`);

            if (vueCallback){
                vueCallback({
                    type: 'nodeselected',
                    data: node,
                });
            }
        }

        if (vueCallback) {
            vueCallback(context);
        }
        return context;
    });

    const applier = new ArrangeAppliers.TransitionApplier<Schemes, never>({
        duration: 500,
        timingFunction: (t:any) => t,
        async onTick() {
            await AreaExtensions.zoomAt(area, editor.getNodes());
        }
    });

    arrange.addPreset(ArrangePresets.classic.setup());

    editor.use(area);
    area.use(connection);
    area.use(render);
    area.use(history);
    area.use(arrange);

    AreaExtensions.simpleNodesOrder(area);

    await AreaExtensions.zoomAt(area, editor.getNodes());

    return {
        setVueCallback: (callback: any) => {
            vueCallback = callback;
        },
        addPipe: (pipe: any) => editor.addPipe(pipe),
        removeSelectedConnections: async () => {
            // DEBUG
            // console.log("Remove selected connections")
            for (const item of [...editor.getConnections()]) {
                if (item.selected) {
                    await editor.removeConnection(item.id);
                }
            }
            for (const item of [...editor.getNodes()]) {
                if (item.selected) {
                    await removeNodeWithConnections(editor, item.id);
                }
            }
        },
        undo: () => history.undo(),
        redo: () => history.redo(),
        destroy: () => area.destroy(),
        layout: async (animate?: boolean) => {
            await _layout_helper(animate);
        },
        importConnections: (connections: ConnectionInterfaceType[]): Promise<(Promise<true>[] | undefined)> => {
            // this function takes in connections, checks whether
            // the graph needs to be changed

            // if the graph needs to be changed, it will also auto-align the graph
            const convertedConnectionsPromise = convertConnectionsToPrefixedRepresentation(
                connections,
                // put the associated entities of nodes and edges in the same array
                (editor.getNodes().map(n => n.entity).concat(editor.getConnections().filter(e=>e.property!==undefined).map(e => e.property ?? noEntity)))
                // I do not know why typescript gives me an error without the default noEntity, but there should be no
                // case where this comes up, especially with the filter statement.
            );

            // TODO this function has a race condition. With the debounce in App.vue this is however very seldom.
            // Leaving this for the future :)

            // Edit: the race condition is resolved by deleting and adding the nodes in sequence
            // this should not be a big performance hit, as the number of nodes probably never exceeds 20
            return Promise.allSettled(convertedConnectionsPromise).then(async values => {
                if (values.every((result) => result.status === "fulfilled")) {
                    const convertedConnections = values.map(v => v.value)

                    // the connections and nodes have to be deleted sequentially instead of in parallel
                    // otherwise the editor gets in a state where connections reference already deleted nodes
                    // which leads to undefined sources/targets
                    for (const conn of editor.getConnections()) {
                        await editor.removeConnection(conn.id);
                    }
                    for (const node of editor.getNodes()) {
                        await editor.removeNode(node.id);
                    }

                    // track nodes in a map to avoid duplicates
                    const nodeMap = new Map();
                    const promises= [];

                    // can be parallel as nodes are not connected yet
                    for (const c of convertedConnections){
                        if(!nodeMap.has(c.source.id)){
                            const subject = createNode(socket, highestIdCount, editor, area);
                            subject.setEntity(c.source);
                            nodeMap.set(c.source.id, subject);
                            promises.push(editor.addNode(subject));
                        }
                        if(!nodeMap.has(c.target.id)){
                            const object = createNode(socket, highestIdCount, editor, area);
                            object.setEntity(c.target);
                            nodeMap.set(c.target.id, object);
                            promises.push(editor.addNode(object));
                        }
                    }

                    await Promise.all(promises);


                    return convertedConnections.map(c => {
                        const subject = nodeMap.get(c.source.id);
                        const object = nodeMap.get(c.target.id);

                        const predicate = new Connection(
                            subject, OUTPUT_SOCKET_NAME, object, INPUT_SOCKET_NAME,
                        )
                        predicate.property = c.property;
                        predicate.selected = false;

                        return new Promise<true>(async function (resolve) {
                            await editor.addConnection(predicate);
                            await _layout_helper(true);
                            resolve(true);
                        });
                    });
                }
            });
        },
        exportConnections: (): ConnectionInterfaceType[] => {
            return exportConnectionsHelper(editor)
        },
        getNode: (id: string) => editor.getNode(id)
    };
}
