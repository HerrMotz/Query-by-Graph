/// <reference lib="webworker" />
// Wraps the Qlue-ls WASM SPARQL language server in a web worker.
//
// The server speaks JSON-RPC over a pair of web streams. This worker translates
// between those streams and `postMessage`, so the main thread can talk plain
// LSP objects (see `src/lib/monaco/sparqlLanguageServer.ts`).
import init, {format_raw, init_language_server, listen} from 'qlue-ls';

init().then(() => {
    const inputStream = new TransformStream<string, string>();
    const outputStream = new TransformStream<string, string>();
    const reader = outputStream.readable.getReader();
    const writer = inputStream.writable.getWriter();

    const server = init_language_server(outputStream.writable.getWriter());
    listen(server, inputStream.readable.getReader());

    self.onmessage = (event: MessageEvent) => {
        // "qbg/formatText" formats a string that is not an open document, so it
        // is answered here from the WASM formatter rather than by the server.
        if (event.data?.method === 'qbg/formatText') {
            let result: string;
            try {
                result = format_raw(event.data.params);
            } catch (error) {
                console.warn('qlue-ls: could not format the query', error);
                result = event.data.params;
            }
            self.postMessage({jsonrpc: '2.0', id: event.data.id, result});
            return;
        }
        writer.write(JSON.stringify(event.data));
    };

    // Forward everything the language server emits back to the main thread.
    (async () => {
        while (true) {
            const {value, done} = await reader.read();
            if (done) break;
            self.postMessage(JSON.parse(value as string));
        }
    })();

    self.postMessage({type: 'ready'});
});
