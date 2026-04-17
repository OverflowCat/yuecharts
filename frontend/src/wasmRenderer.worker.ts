type WasmBackend = 'gc' | 'linear';

type InitMessage = {
  type: 'init';
  backend: WasmBackend;
  wasmUrl: string;
};

type RenderMessage = {
  type: 'render';
  id: number;
  json: string;
};

type DisposeMessage = {
  type: 'dispose';
};

type WorkerMessage = InitMessage | RenderMessage | DisposeMessage;

type ReadyMessage = {
  type: 'ready';
  version: string;
};

type ResultMessage = {
  type: 'result';
  id: number;
  svg: string;
};

type ErrorMessage = {
  type: 'error';
  id?: number;
  error: string;
};

type WorkerContext = {
  postMessage: (message: unknown) => void;
  close: () => void;
  addEventListener: (
    type: 'message',
    listener: (event: MessageEvent<WorkerMessage>) => void,
  ) => void;
};

const ctx = self as unknown as WorkerContext;

let initPromise: Promise<void> | null = null;
let renderFn: ((json: string) => string) | null = null;
let disposed = false;

function errorMessage(error: unknown) : string {
  if (error instanceof Error) {
    return error.message;
  }
  return String(error);
}

async function instantiateWasm(
  wasmUrl : string,
  imports : WebAssembly.Imports,
  compileOptions : Record<string, unknown> | undefined,
) : Promise<WebAssembly.WebAssemblyInstantiatedSource> {
  const res = await fetch(wasmUrl);
  const wasmAny = WebAssembly as unknown as {
    instantiateStreaming?: (
      source : Response,
      importObject : WebAssembly.Imports,
      compileOptions?: Record<string, unknown>,
    ) => Promise<WebAssembly.WebAssemblyInstantiatedSource>
    instantiate: (
      source : BufferSource,
      importObject : WebAssembly.Imports,
      compileOptions?: Record<string, unknown>,
    ) => Promise<WebAssembly.WebAssemblyInstantiatedSource>
  }
  if (typeof wasmAny.instantiateStreaming === 'function') {
    try {
      return await wasmAny.instantiateStreaming(
        res.clone(),
        imports,
        compileOptions,
      )
    } catch {
      // Fall through to arrayBuffer instantiation when streaming is unavailable.
    }
  }
  const bytes = await res.arrayBuffer()
  return await wasmAny.instantiate(bytes, imports, compileOptions)
}

async function initRenderer(message : InitMessage) : Promise<string> {
  if (message.backend === 'gc') {
    const result = await instantiateWasm(
      message.wasmUrl,
      {},
      {
        builtins: ['js-string'],
        importedStringConstants: '_',
      },
    )
    const exports = result.instance.exports as Record<string, unknown>
    const start = exports._start
    if (typeof start === 'function') {
      start()
    }
    const version = exports.version
    const versionText = typeof version === 'function' ? String(version()) : '?'
    const render = exports.render
    if (typeof render !== 'function') {
      throw new Error('Missing render export')
    }
    renderFn = (json : string) => String(render(json))
    return versionText
  }

  let inputStr = ''
  let inputPos = 0
  const outputChars : string[] = []
  const importObject = {
    spectest: {
      print_char: (ch : number) => {
        outputChars.push(String.fromCharCode(ch))
      },
    },
    input: {
      getchar: () =>
        inputPos < inputStr.length ? inputStr.charCodeAt(inputPos++) : -1,
    },
  }
  const result = await instantiateWasm(message.wasmUrl, importObject, undefined)
  const exports = result.instance.exports as Record<string, unknown>
  const start = exports._start
  if (typeof start === 'function') {
    start()
  }
  const version = exports.version
  const versionText = typeof version === 'function' ? String(version()) : '?'
  const doRender = exports.do_render
  if (typeof doRender !== 'function') {
    throw new Error('Missing do_render export')
  }
  renderFn = (json : string) => {
    inputStr = json
    inputPos = 0
    outputChars.length = 0
    doRender()
    let svg = outputChars.join('')
    if (svg.endsWith('\n')) {
      svg = svg.slice(0, -1)
    }
    return svg
  }
  return versionText
}

async function handleInit(message : InitMessage) : Promise<void> {
  const versionText = await initRenderer(message)
  ctx.postMessage({
    type: 'ready',
    version: versionText,
  } satisfies ReadyMessage)
}

async function handleRender(message : RenderMessage) : Promise<void> {
  if (!initPromise) {
    throw new Error('Worker is not initialized')
  }
  await initPromise
  if (disposed) {
    return
  }
  if (!renderFn) {
    throw new Error('Renderer is not ready')
  }
  const svg = renderFn(message.json)
  ctx.postMessage({
    type: 'result',
    id: message.id,
    svg,
  } satisfies ResultMessage)
}

ctx.addEventListener('message', (event : MessageEvent<WorkerMessage>) => {
  const message = event.data
  if (disposed) {
    return
  }
  if (message.type === 'init') {
    if (initPromise) {
      return
    }
    initPromise = handleInit(message).catch((error) => {
      ctx.postMessage({
        type: 'error',
        error: errorMessage(error),
      } satisfies ErrorMessage)
      throw error
    })
    return
  }
  if (message.type === 'render') {
    void handleRender(message).catch((error) => {
      ctx.postMessage({
        type: 'error',
        id: message.id,
        error: errorMessage(error),
      } satisfies ErrorMessage)
    })
    return
  }
  disposed = true
  ctx.close()
})
