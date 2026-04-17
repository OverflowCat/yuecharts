export type WasmBackend = 'gc' | 'linear';

export interface Renderer {
  render: (json: string) => Promise<string | null>;
  version: () => string;
  dispose: () => void;
}

type WorkerJob = {
  id: number;
  json: string;
  resolve: (svg: string | null) => void;
  reject: (error: Error) => void;
};

type WorkerSlot = {
  worker: Worker;
  ready: boolean;
  busy: boolean;
  alive: boolean;
  version: string;
  resolveReady: () => void;
  rejectReady: (error: Error) => void;
};

type WorkerReadyMessage = {
  type: 'ready';
  version: string;
};

type WorkerResultMessage = {
  type: 'result';
  id: number;
  svg: string;
};

type WorkerErrorMessage = {
  type: 'error';
  id?: number;
  error: string;
};

export class WasmWorkerRenderer implements Renderer {
  private readonly slots: Array<WorkerSlot> = [];
  private readonly queue: Array<WorkerJob> = [];
  private readonly readySignal: Promise<void>;
  private readonly disposeWorker: () => void;
  private nextJobId = 0;
  private versionText = '?';
  private disposed = false;

  constructor(
    private readonly backend: WasmBackend,
    private readonly wasmUrl: string,
    workerCount: number,
  ) {
    const readyPromises: Array<Promise<void>> = [];
    for (let i = 0; i < workerCount; i += 1) {
      const worker = new Worker(new URL('./wasmRenderer.worker.ts', import.meta.url), {
        type: 'module',
      });
      let resolveReady: () => void = () => {};
      let rejectReady: (error: Error) => void = () => {};
      const readyPromise = new Promise<void>((resolve, reject) => {
        resolveReady = resolve;
        rejectReady = reject;
      });
      const slot: WorkerSlot = {
        worker,
        ready: false,
        busy: false,
        alive: true,
        version: '?',
        resolveReady,
        rejectReady,
      };
      worker.addEventListener('message', (event: MessageEvent<WorkerReadyMessage | WorkerResultMessage | WorkerErrorMessage>) => {
        const message = event.data;
        if (this.disposed || !slot.alive) {
          return;
        }
        if (message.type === 'ready') {
          slot.ready = true;
          slot.version = message.version || '?';
          if (this.versionText === '?' && slot.version !== '?') {
            this.versionText = slot.version;
          }
          slot.resolveReady();
          this.drainQueue();
          return;
        }
        if (message.type === 'result') {
          const job = (slot as WorkerSlot & { currentJob?: WorkerJob }).currentJob;
          delete (slot as WorkerSlot & { currentJob?: WorkerJob }).currentJob;
          slot.busy = false;
          if (job) {
            job.resolve(message.svg);
          }
          this.drainQueue();
          return;
        }
        const job = (slot as WorkerSlot & { currentJob?: WorkerJob }).currentJob;
        delete (slot as WorkerSlot & { currentJob?: WorkerJob }).currentJob;
        slot.busy = false;
        if (job && typeof message.id === 'number' && message.id === job.id) {
          job.reject(new Error(message.error));
        }
        this.failSlot(slot, new Error(message.error));
      });
      worker.addEventListener('error', (event : ErrorEvent) => {
        this.failSlot(slot, event.error ?? new Error(event.message || 'Worker error'));
      });
      worker.postMessage({
        type: 'init',
        backend: this.backend,
        wasmUrl: this.wasmUrl,
      });
      readyPromises.push(readyPromise);
      this.slots.push(slot);
    }
    this.readySignal = Promise.any(readyPromises).then(() => undefined);
    this.disposeWorker = () => {
      for (const slot of this.slots) {
        slot.worker.terminate();
      }
    };
  }

  ready(): Promise<void> {
    return this.readySignal;
  }

  render(json: string): Promise<string | null> {
    if (this.disposed) {
      return Promise.reject(new Error('Renderer has been disposed'));
    }
    return new Promise<string | null>((resolve, reject) => {
      this.queue.push({
        id: this.nextJobId += 1,
        json,
        resolve,
        reject,
      });
      this.drainQueue();
    });
  }

  version(): string {
    return this.versionText;
  }

  dispose(): void {
    if (this.disposed) {
      return;
    }
    this.disposed = true;
    for (const job of this.queue) {
      job.reject(new Error('Renderer has been disposed'));
    }
    this.queue.length = 0;
    this.disposeWorker();
  }

  private failSlot(slot: WorkerSlot, error: Error): void {
    if (!slot.alive) {
      return;
    }
    slot.alive = false;
    slot.rejectReady(error);
    const currentJob = (slot as WorkerSlot & { currentJob?: WorkerJob }).currentJob;
    if (currentJob) {
      delete (slot as WorkerSlot & { currentJob?: WorkerJob }).currentJob;
      slot.busy = false;
      currentJob.reject(error);
    }
    this.drainQueue();
  }

  private pickIdleSlot(): WorkerSlot | null {
    for (const slot of this.slots) {
      if (slot.alive && slot.ready && !slot.busy) {
        return slot;
      }
    }
    return null;
  }

  private drainQueue(): void {
    if (this.disposed) {
      return;
    }
    while (this.queue.length > 0) {
      const slot = this.pickIdleSlot();
      if (!slot) {
        return;
      }
      const job = this.queue.shift()!;
      slot.busy = true;
      (slot as WorkerSlot & { currentJob?: WorkerJob }).currentJob = job;
      slot.worker.postMessage({
        type: 'render',
        id: job.id,
        json: job.json,
      });
    }
  }
}

export async function createWasmRendererPool(
  backend: WasmBackend,
  wasmUrl: string,
  workerCount = 1,
): Promise<Renderer> {
  const renderer = new WasmWorkerRenderer(backend, wasmUrl, workerCount);
  await renderer.ready();
  return renderer;
}
