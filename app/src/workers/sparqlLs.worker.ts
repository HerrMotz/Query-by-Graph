/// <reference lib="webworker" />
// Wraps the Qlue-ls WASM SPARQL language server in a web worker.
//
// The server speaks JSON-RPC over a pair of web streams. This worker translates
// between those streams and `postMessage`, so the main thread can talk plain
// LSP objects (see `src/lib/monaco/sparqlLanguageServer.ts`).
import init, {format_raw, init_language_server, listen} from 'qlue-ls';

/** Tell the client that the server is gone, so it stops waiting for answers. */
const reportFailure = (context: string, error: unknown) => {
    console.error(`qlue-ls: ${context}`, error);
    self.postMessage({type: 'error', error: `${context}: ${error}`});
};

const start = async () => {
    await init();

    const inputStream = new TransformStream<string, string>();
    const outputStream = new TransformStream<string, string>();
    const reader = outputStream.readable.getReader();
    const writer = inputStream.writable.getWriter();

    const server = init_language_server(outputStream.writable.getWriter());
    listen(server, inputStream.readable.getReader())
        .catch(error => reportFailure('the language server stopped listening', error));

    self.onmessage = (event: MessageEvent) => {
        // qlue-ls exposes its formatter as a plain function next to the
        // language server, so formatting a string needs no open document and
        // does not go through JSON-RPC. `null` tells the client to keep the
        // text it has.
        if (event.data?.type === 'format') {
            let text: string | null = null;
            try {
                text = format_raw(event.data.text);
            } catch (error) {
                console.warn('qlue-ls: could not format the query', error);
            }
            self.postMessage({type: 'formatted', id: event.data.id, text});
            return;
        }

        writer.write(JSON.stringify(event.data))
            .catch(error => reportFailure('could not send a request to the language server', error));
    };

    // Forward everything the language server emits back to the main thread.
    (async () => {
        while (true) {
            const {value, done} = await reader.read();
            if (done) break;
            self.postMessage(JSON.parse(value as string));
        }
    })().catch(error => reportFailure('the connection to the language server broke', error));

    self.postMessage({type: 'ready'});
};

start().catch(error => reportFailure('the language server could not be started', error));
