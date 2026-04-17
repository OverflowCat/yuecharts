import { defineConfig } from 'vite'
import { svelte } from '@sveltejs/vite-plugin-svelte'
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

// Serve the yuecharts root (parent dir) as static files so that
//   cmd/wasm/*.wasm and examples/*.json are accessible in dev.
const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const FRONTEND_DIR = path.dirname(fileURLToPath(import.meta.url))
const DIST_DIR = path.resolve(FRONTEND_DIR, 'dist')
const EXAMPLE_JS_SRC = path.join(ROOT, 'examples', 'js')
const EXAMPLE_JS_DST = path.join(DIST_DIR, 'examples', 'js')
const WASM_SRC_DIR = path.join(ROOT, 'cmd', 'wasm')
const WASM_DST_DIR = path.join(DIST_DIR, 'cmd', 'wasm')
const MIME: Record<string, string> = {
  '.wasm': 'application/wasm',
  '.json': 'application/json',
  '.svg':  'image/svg+xml',
  '.js':   'text/javascript',
}

function copyExampleScripts() {
  if (!fs.existsSync(EXAMPLE_JS_SRC)) return
  fs.mkdirSync(EXAMPLE_JS_DST, { recursive: true })
  fs.cpSync(EXAMPLE_JS_SRC, EXAMPLE_JS_DST, { recursive: true, force: true })
}

function copyWasmArtifacts() {
  if (!fs.existsSync(WASM_SRC_DIR)) {
    throw new Error(`Missing WASM source directory: ${WASM_SRC_DIR}`)
  }
  const missing: string[] = []
  for (const fileName of ['wasm-gc.wasm', 'wasm.wasm']) {
    const src = path.join(WASM_SRC_DIR, fileName)
    if (!fs.existsSync(src)) {
      missing.push(fileName)
      continue
    }
    const dst = path.join(WASM_DST_DIR, fileName)
    fs.mkdirSync(path.dirname(dst), { recursive: true })
    fs.copyFileSync(src, dst)
  }
  if (missing.length > 0) {
    throw new Error(`Missing WASM artifacts in ${WASM_SRC_DIR}: ${missing.join(', ')}. Run build-wasm.ps1 first.`)
  }
}

function copyStaticArtifacts() {
  copyExampleScripts()
  copyWasmArtifacts()
}

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    svelte(),
    {
      name: 'serve-yuecharts-root',
      configureServer(server) {
        server.middlewares.use((req, res, next) => {
          const url = (req.url ?? '/').split('?')[0]
          const filePath = path.join(ROOT, url)
          try {
            if (fs.statSync(filePath).isFile()) {
              res.setHeader('Content-Type', MIME[path.extname(filePath)] ?? 'application/octet-stream')
              fs.createReadStream(filePath).pipe(res)
              return
            }
          } catch { /* not found */ }
          next()
        })
      },
    },
    {
      name: 'copy-static-artifacts',
      closeBundle() {
        copyStaticArtifacts()
      },
    },
  ],
})
