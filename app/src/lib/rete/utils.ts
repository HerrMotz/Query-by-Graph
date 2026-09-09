import { BaseSchemes, NodeEditor, NodeId } from "rete";

export async function removeNodeWithConnections(
    editor: NodeEditor<BaseSchemes>,
    nodeId: NodeId
) {
    for (const item of [...editor.getConnections()]) {
        if (item.source === nodeId || item.target === nodeId) {
            await editor.removeConnection(item.id);
        }
    }
    await editor.removeNode(nodeId);
}
