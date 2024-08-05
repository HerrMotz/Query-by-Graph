import {NodeEditor, GetSchemes, ClassicPreset} from "rete";
import {AreaPlugin, AreaExtensions, Area2D} from "rete-area-plugin";
import {
    ConnectionPlugin,
    Presets as ConnectionPresets
} from "rete-connection-plugin";
import {ConnectionPathPlugin} from "rete-connection-path-plugin";
// See https://retejs.org/examples/connection-path
import { curveStep, CurveFactory } from "d3-shape";
import {
    HistoryExtensions,
    HistoryPlugin,
    Presets as HistoryPresets
} from "rete-history-plugin";
import {VuePlugin, Presets, VueArea2D} from "rete-vue-plugin";
import {h} from "vue";
import CustomConnection from "../../components/CustomConnection.vue";
import {removeNodeWithConnections} from "./utils.ts";
import EntityType from "../types/EntityType.ts";

class Connection extends ClassicPreset.Connection<
    ClassicPreset.Node,
    ClassicPreset.Node
> {
    selected?: boolean;
    property?: EntityType;
    curve?: CurveFactory;
}

type Schemes = GetSchemes<ClassicPreset.Node, Connection>;
type AreaExtra = VueArea2D<Schemes>;

export async function createEditor(container: HTMLElement) {
    const socket = new ClassicPreset.Socket("socket");

    const editor = new NodeEditor<Schemes>();
    const area = new AreaPlugin<Schemes, AreaExtra>(container);
    const connection = new ConnectionPlugin<Schemes, AreaExtra>();
    const render = new VuePlugin<Schemes, AreaExtra>();
    const selector = AreaExtensions.selector();
    const accumulating = AreaExtensions.accumulateOnCtrl();
    const history = new HistoryPlugin<Schemes>();

    HistoryExtensions.keyboard(history);

    history.addPreset(HistoryPresets.classic.setup());

    let selectedProperty: EntityType | null = null;
    let selectedIndividual: EntityType | null = null;

    function SelectableConnectionBind(props: { data: Schemes["Connection"] }) {
        const id = props.data.id;

        // TODO keep the existing properties
        //  this is a "might do" feature
        props.data.property = {
            id: selectedProperty?.id || "No ID",
            label: selectedProperty?.label || "No Label"
        }
        const label = "connection";

        // Initialize the custom connection with the custom props
        // and connect it to our editor events
        return h(CustomConnection, {
            ...props, onClick: () => {
                console.log("Selected connection", id)
                selector.add(
                    {
                        id,
                        label,
                        translate() {},
                        unselect() {
                            props.data.selected = false;
                            area.update("connection", id);
                        }
                    },
                    accumulating.active()
                );
                props.data.selected = true;
                area.update("connection", id);
            }
        });
    }

    AreaExtensions.selectableNodes(area, selector, {
        accumulating: accumulating
    });

    render.addPreset(Presets.classic.setup({
        customize: {
            connection() {
                return SelectableConnectionBind;
            }
        }
    }));

    const pathPlugin = new ConnectionPathPlugin<Schemes, Area2D<Schemes>>({
        curve: (c) => c.curve || curveStep,
        // transformer: () => Transformers.classic({ vertical: false }),
        arrow: () => true
    });

    // @ts-ignore
    render.use(pathPlugin);

    connection.addPreset(ConnectionPresets.classic.setup());

    area.addPipe(async (context) => {
        if (context.type === "contextmenu") {
            const source = context.data.context;
            const event = context.data.event;
            event.preventDefault();
            event.stopPropagation();

            if (source === "root") {
                console.log("Add node")

                let nodeLabel;

                // check if it is a variable individual
                // if so, find the highest variable id, increment it by one and assign
                // it to the "to be created"-node
                if (selectedIndividual?.id.startsWith("?")) {
                    const highestId = editor.getNodes()
                        .filter(n => n.label.startsWith("?"))
                        .sort()
                        .reverse()[0];

                    if (!highestId) {
                        selectedIndividual.id = "?1";
                    } else {
                        selectedIndividual.id = "?" + (parseInt(highestId.label.slice(1)) + 1);
                    }

                    selectedIndividual.label = ""
                    nodeLabel = selectedIndividual.id

                } else {
                    nodeLabel = (selectedIndividual?.id || "No ID") + ", " + (selectedIndividual?.label || "No Label")
                }

                const node = new ClassicPreset.Node(
                    nodeLabel
                );

                node.addInput("a", new ClassicPreset.Input(socket));
                node.addOutput("b", new ClassicPreset.Output(socket));
                await editor.addNode(node);
                area.area.setPointerFrom(event);

                await area.translate(node.id, area.area.pointer);
            } else if (source instanceof ClassicPreset.Node) {
                console.log("Remove node", source.id);
                for (const c of editor
                    .getConnections()
                    .filter((c) => c.source === source.id || c.target === source.id)) {
                    await editor.removeConnection(c.id);
                }
                await editor.removeNode(source.id);
            }
        }

        return context;
    });

    editor.use(area);
    area.use(connection);
    area.use(render);
    area.use(history);

    AreaExtensions.simpleNodesOrder(area);

    await AreaExtensions.zoomAt(area, editor.getNodes());

    return {
        removeSelectedConnections: async () => {
            console.log("Remove selected connections")
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
        setSelectedProperty: (property: EntityType) => {
            selectedProperty = property
        },
        setSelectedIndividual: (individual: EntityType) => {
            selectedIndividual = individual
        },
        undo: () => history.undo(),
        redo: () => history.redo(),
        destroy: () => area.destroy()
    };
}
