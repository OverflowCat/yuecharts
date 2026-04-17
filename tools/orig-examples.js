#!/usr/bin/env node
'use strict';

const fs = require('fs');
const http = require('http');
const path = require('path');
const { spawnSync } = require('child_process');

const CURRENT_ROOT = path.resolve(__dirname, '..');
const ORIGINAL_ROOT = 'E:/recharts/echarts-examples';
const ECHARTS_ROOT = 'E:/recharts/echarts';

const CURRENT_EXAMPLES_DIR = path.join(CURRENT_ROOT, 'examples');
const ORIG_EXAMPLES_DIR = path.join(CURRENT_ROOT, 'orig-examples');
const TMP_ROOT = path.join(CURRENT_ROOT, '_tmp', 'orig-examples');
const TMP_ORIG_SVG_DIR = path.join(TMP_ROOT, 'svg-browser', 'original');
const TMP_MBT_SVG_DIR = path.join(TMP_ROOT, 'svg-browser', 'moonbit');
const TMP_REPORT_PATH = path.join(TMP_ROOT, 'report-browser.json');
const README_PATH = path.join(ORIG_EXAMPLES_DIR, 'README.md');
const MOON_BINARY_PATH = path.join(
  CURRENT_ROOT,
  '_build',
  'native',
  'debug',
  'build',
  'cmd',
  'main',
  'main.exe'
);

const puppeteer = require(path.join(
  ORIGINAL_ROOT,
  'node_modules',
  'puppeteer'
));
const matter = require(path.join(ORIGINAL_ROOT, 'node_modules', 'gray-matter'));
const minimatch = require(path.join(ORIGINAL_ROOT, 'node_modules', 'minimatch'));
const { loadEchartsExampleFile } = require('./option-loader');

const SVG_WIDTH = 600;
const SVG_HEIGHT = 400;
const DEFAULT_WAIT_MS = 500;
const CHROME_EXE_PATH = 'C:/Program Files/Google/Chrome/Application/chrome.exe';
const MOONBIT_TOP_FIELDS = ['width', 'height', 'maps'];

function ensureDir(dirPath) {
  fs.mkdirSync(dirPath, { recursive: true });
}

function walkFiles(rootDir, allowedExts) {
  const files = [];
  const stack = [rootDir];
  while (stack.length > 0) {
    const dir = stack.pop();
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        stack.push(fullPath);
      } else if (
        !allowedExts ||
        allowedExts.includes(path.extname(entry.name).toLowerCase())
      ) {
        files.push(fullPath);
      }
    }
  }
  return files.sort((a, b) => a.localeCompare(b));
}

function toPosixRel(rootDir, filePath) {
  return path.relative(rootDir, filePath).replace(/\\/g, '/');
}

function getCurrentExampleBaseNames() {
  const basenames = new Set();
  for (const filePath of walkFiles(CURRENT_EXAMPLES_DIR, ['.json', '.js'])) {
    basenames.add(path.basename(filePath, path.extname(filePath)));
  }
  return basenames;
}

function getOriginalExampleFiles() {
  const sourceRoot = path.join(ORIGINAL_ROOT, 'public', 'examples', 'ts');
  return walkFiles(sourceRoot, ['.ts', '.js']);
}

function getOriginalExampleId(sourceRoot, filePath) {
  return toPosixRel(sourceRoot, filePath).replace(/\.(ts|js)$/, '');
}

function getOriginalOutputPath(sourceRoot, filePath) {
  const rel = path.relative(sourceRoot, filePath);
  return path.join(ORIG_EXAMPLES_DIR, rel).replace(/\.(ts|js)$/, '.json');
}

function getOriginalCompiledJsPath(sourceRoot, filePath) {
  const rel = path.relative(sourceRoot, filePath);
  return path.join(
    ORIGINAL_ROOT,
    'public',
    'examples',
    'js',
    rel
  ).replace(/\.(ts|js)$/, '.js');
}

function resolveOriginalSourcePath(exampleId) {
  const sourceRoot = path.join(ORIGINAL_ROOT, 'public', 'examples', 'ts');
  const candidates = [
    path.join(sourceRoot, `${exampleId}.ts`),
    path.join(sourceRoot, `${exampleId}.js`)
  ];
  for (const candidate of candidates) {
    if (fs.existsSync(candidate)) {
      return candidate;
    }
  }
  return null;
}

function resolveCurrentExampleJsonPath(exampleId) {
  const currentExamplePath = path.join(CURRENT_EXAMPLES_DIR, `${exampleId}.json`);
  return fs.existsSync(currentExamplePath) ? currentExamplePath : null;
}

function needsBuiltinMap(sourceText, mapName) {
  const escaped = mapName.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const pattern = new RegExp(
    String.raw`(?:mapType|map)\s*:\s*['"]${escaped}['"]`,
    'i'
  );
  return pattern.test(sourceText);
}

async function preloadBuiltinMaps(page, sourceText) {
  if (needsBuiltinMap(sourceText, 'china')) {
    const chinaMapJsPath = path.join(
      ECHARTS_ROOT,
      'test',
      'data',
      'map',
      'js',
      'china.js'
    );
    if (fs.existsSync(chinaMapJsPath)) {
      await page.addScriptTag({ path: chinaMapJsPath });
    }
  }

  if (needsBuiltinMap(sourceText, 'world')) {
    const worldMapJsonPath = path.join(
      ECHARTS_ROOT,
      'test',
      'data',
      'map',
      'json',
      'world.json'
    );
    if (fs.existsSync(worldMapJsonPath)) {
      const worldMap = JSON.parse(readText(worldMapJsonPath));
      await page.evaluate((geoJSON) => {
        if (window.echarts && typeof window.echarts.registerMap === 'function') {
          window.echarts.registerMap('world', geoJSON);
        }
      }, worldMap);
    }
  }
}

function getOriginalExportFiles(patterns) {
  const sourceRoot = path.join(ORIGINAL_ROOT, 'public', 'examples', 'ts');
  const currentBaseNames = getCurrentExampleBaseNames();
  const allFiles = getOriginalExampleFiles();
  return allFiles.filter((filePath) => {
    const baseName = path.basename(filePath, path.extname(filePath));
    if (currentBaseNames.has(baseName)) {
      return false;
    }
    if (!patterns || patterns.length === 0) {
      return true;
    }
    const id = getOriginalExampleId(sourceRoot, filePath);
    return patterns.some((pattern) => minimatch(id, pattern));
  });
}

function parseArgs(argv) {
  const result = {
    command: 'all',
    patterns: [],
    compile: false,
    skipExisting: false,
    help: false
  };

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === 'export' || arg === 'compare' || arg === 'all') {
      result.command = arg;
      continue;
    }
    if (arg === '--compile') {
      result.compile = true;
      continue;
    }
    if (arg === '--skip-existing') {
      result.skipExisting = true;
      continue;
    }
    if (arg === '--help' || arg === '-h') {
      result.help = true;
      continue;
    }
    if (arg.startsWith('--pattern=')) {
      result.patterns = arg.slice('--pattern='.length).split(',');
      continue;
    }
    if (arg === '--pattern') {
      i += 1;
      if (argv[i]) {
        result.patterns = argv[i].split(',');
      }
      continue;
    }
    throw new Error(`Unknown argument: ${arg}`);
  }

  return result;
}

function printHelp() {
  process.stdout.write(
    [
      'Usage:',
      '  node tools/orig-examples.js export [--compile] [--pattern=glob]',
      '  node tools/orig-examples.js compare [--skip-existing] [--pattern=glob]',
      '  node tools/orig-examples.js all [--compile] [--pattern=glob]',
      '',
      'Commands:',
      '  export   Extract plain JSON from original examples into orig-examples/',
      '  compare  Render orig-examples JSON with original ECharts and MoonBit',
      '  all      Run export then compare',
      '',
      'Options:',
      '  --compile   Rebuild original example JS output before exporting',
      '  --skip-existing   Reuse already rendered SVG pairs from _tmp/orig-examples/svg-browser',
      '  --pattern   Comma-separated minimatch patterns for example ids',
      ''
    ].join('\n')
  );
}

function compileOriginalExamples() {
  const jsDir = path.join(ORIGINAL_ROOT, 'public', 'examples', 'js');
  if (!fs.existsSync(jsDir)) {
    ensureDir(jsDir);
  }

  const result = spawnSync('npm', ['run', 'compile:example'], {
    cwd: ORIGINAL_ROOT,
    encoding: 'utf8',
    stdio: 'inherit'
  });

  if (result.status !== 0) {
    throw new Error('npm run compile:example failed');
  }
}

function ensureMoonBinary() {
  if (fs.existsSync(MOON_BINARY_PATH)) {
    return MOON_BINARY_PATH;
  }

  const result = spawnSync('moon', ['build', '--target', 'native'], {
    cwd: CURRENT_ROOT,
    encoding: 'utf8',
    stdio: 'inherit'
  });

  if (result.status !== 0) {
    throw new Error('moon build --target native failed');
  }

  if (!fs.existsSync(MOON_BINARY_PATH)) {
    throw new Error(`MoonBit native binary not found: ${MOON_BINARY_PATH}`);
  }

  return MOON_BINARY_PATH;
}

function createStaticServer(rootDir) {
  const resolvedRoot = path.resolve(rootDir);

  function mimeType(filePath) {
    switch (path.extname(filePath).toLowerCase()) {
      case '.html':
        return 'text/html; charset=utf-8';
      case '.js':
      case '.mjs':
        return 'application/javascript; charset=utf-8';
      case '.css':
        return 'text/css; charset=utf-8';
      case '.json':
        return 'application/json; charset=utf-8';
      case '.svg':
        return 'image/svg+xml; charset=utf-8';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.gif':
        return 'image/gif';
      case '.mp3':
        return 'audio/mpeg';
      default:
        return 'application/octet-stream';
    }
  }

  const server = http.createServer((req, res) => {
    const requestUrl = new URL(req.url, 'http://localhost');
    let pathname = decodeURIComponent(requestUrl.pathname);
    if (pathname === '/') {
      pathname = '/tool/screenshot.html';
    }

    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, HEAD, OPTIONS',
      'Access-Control-Allow-Headers': '*'
    };

    if (req.method === 'OPTIONS') {
      res.writeHead(204, corsHeaders);
      res.end();
      return;
    }

    const filePath = path.resolve(resolvedRoot, `.${pathname}`);
    const relativePath = path.relative(resolvedRoot, filePath);
    if (relativePath.startsWith('..') || path.isAbsolute(relativePath)) {
      res.writeHead(403, corsHeaders);
      res.end('Forbidden');
      return;
    }

    fs.stat(filePath, (err, stat) => {
      if (err) {
        res.writeHead(404, corsHeaders);
        res.end('Not found');
        return;
      }

      let targetPath = filePath;
      if (stat.isDirectory()) {
        targetPath = path.join(filePath, 'index.html');
      }

      fs.readFile(targetPath, (readErr, data) => {
        if (readErr) {
          res.writeHead(404, corsHeaders);
          res.end('Not found');
          return;
        }
        res.writeHead(200, {
          ...corsHeaders,
          'Content-Type': mimeType(targetPath)
        });
        res.end(data);
      });
    });
  });

  return server;
}

function normalizeSvg(svg) {
  return svg
    .replace(/\r/g, '')
    .replace(/>\s+</g, '><')
    .replace(/\s+/g, ' ')
    .trim();
}

function writeUtf8(filePath, content) {
  ensureDir(path.dirname(filePath));
  fs.writeFileSync(filePath, content, {
    encoding: 'utf8'
  });
}

function delayMs(delay) {
  return new Promise((resolve) => setTimeout(resolve, delay));
}

async function waitForOptionText(page, timeoutMs) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    const optionText = await page.evaluate(() => {
      if (typeof option !== 'undefined' && option != null) {
        return JSON.stringify(option);
      }
      return null;
    });
    if (optionText != null) {
      return optionText;
    }
    await delayMs(200);
  }
  return null;
}

function readText(filePath) {
  return fs.readFileSync(filePath, 'utf8');
}

function extractShotDelay(sourceText) {
  try {
    const parsed = matter(sourceText, { delimiters: ['/*', '*/'] });
    const rawDelay = parsed.data && parsed.data.shotDelay;
    if (rawDelay == null || rawDelay === '') {
      return 0;
    }
    const delay = Number(rawDelay);
    return Number.isFinite(delay) ? delay : 0;
  } catch (_err) {
    return 0;
  }
}

async function exportOrigExamples(patterns, compileFirst) {
  if (compileFirst) {
    compileOriginalExamples();
  }

  const sourceRoot = path.join(ORIGINAL_ROOT, 'public', 'examples', 'ts');
  const exampleFiles = getOriginalExportFiles(patterns);

  ensureDir(ORIG_EXAMPLES_DIR);
  ensureDir(TMP_ROOT);

  const results = [];
  try {
    for (const filePath of exampleFiles) {
      const relativeSource = toPosixRel(sourceRoot, filePath);
      const exampleId = relativeSource.replace(/\.(ts|js)$/, '');
      const outputPath = getOriginalOutputPath(sourceRoot, filePath);
      const currentExamplePath = resolveCurrentExampleJsonPath(exampleId);

      try {
        let outputText;
        if (currentExamplePath) {
          const currentJson = JSON.parse(readText(currentExamplePath));
          outputText = `${JSON.stringify(currentJson, null, 2)}\n`;
        } else {
          const compiledJsPath = getOriginalCompiledJsPath(sourceRoot, filePath);
          const runtimePath = fs.existsSync(compiledJsPath) ? compiledJsPath : filePath;
          const evaluated = await loadEchartsExampleFile(
            runtimePath,
            path.join(ORIGINAL_ROOT, 'public')
          );
          const outputJson = { ...evaluated.option };
          if (Array.isArray(evaluated.maps) && evaluated.maps.length > 0) {
            outputJson.maps = evaluated.maps;
          }
          outputText = `${JSON.stringify(outputJson, null, 2)}\n`;
        }

        writeUtf8(outputPath, outputText);
        results.push({
          id: exampleId,
          source: relativeSource,
          output: toPosixRel(CURRENT_ROOT, outputPath),
          status: 'exported'
        });
        process.stdout.write(`exported ${exampleId}\n`);
      } catch (err) {
        results.push({
          id: exampleId,
          source: relativeSource,
          output: toPosixRel(CURRENT_ROOT, outputPath),
          status: 'export-failed',
          error: String(err && err.message ? err.message : err)
        });
        process.stderr.write(`export failed ${exampleId}: ${err}\n`);
      }
    }
  } catch (err) {
    process.stderr.write(`export failed fatally: ${err}\n`);
    results.push({
      id: '*',
      source: '',
      output: '',
      status: 'export-failed',
      error: String(err && err.message ? err.message : err)
    });
  }
  return results;
}

function renderMoonSvg(jsonText) {
  const binaryPath = ensureMoonBinary();
  const result = spawnSync(binaryPath, [], {
    cwd: CURRENT_ROOT,
    input: jsonText,
    encoding: 'utf8',
    maxBuffer: 50 * 1024 * 1024
  });

  const combined = `${result.stdout || ''}${result.stderr || ''}`;
  const lines = combined.split(/\r?\n/);
  const svgLines = lines.filter((line) => line.trimStart().startsWith('<'));
  const svg = svgLines.join('\n').trimEnd();
  return {
    ok: result.status === 0 && svg.length > 0,
    svg,
    raw: combined,
    status: result.status,
    stderr: result.stderr || ''
  };
}

function renderOriginalSvg(option) {
  const echarts = require(path.join(ECHARTS_ROOT, 'dist', 'echarts'));
  const chart = echarts.init(null, null, {
    renderer: 'svg',
    ssr: true,
    width: SVG_WIDTH,
    height: SVG_HEIGHT
  });
  chart.setOption(option, true);
  const svg = chart.renderToSVGString();
  chart.dispose();
  return svg;
}

async function createOriginalBrowserRenderer() {
  const rootServer = createStaticServer(ORIGINAL_ROOT);
  const port = await new Promise((resolve) => {
    rootServer.listen(0, '127.0.0.1', () => {
      const address = rootServer.address();
      resolve(address.port);
    });
  });
  const origin = `http://127.0.0.1:${port}`;
  const browser = await puppeteer.launch({
    headless: true,
    executablePath: fs.existsSync(CHROME_EXE_PATH) ? CHROME_EXE_PATH : undefined,
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-gpu']
  });

  const page = await browser.newPage();
  await page.setViewport({ width: SVG_WIDTH, height: SVG_HEIGHT });
  await page.setRequestInterception(true);
  page.on('request', (request) => {
    let pathname;
    try {
      pathname = decodeURIComponent(new URL(request.url()).pathname);
    } catch (_err) {
      request.continue();
      return;
    }

    const geoMatch = pathname.match(
      /(?:^|\/)(?:public\/)?data\/asset\/geo\/(USA|HK)\.json$/i
    );
    if (geoMatch) {
      const filePath = path.join(
        ORIGINAL_ROOT,
        'public',
        'data',
        'asset',
        'geo',
        `${geoMatch[1].toUpperCase()}.json`
      );
      if (fs.existsSync(filePath)) {
        request.respond({
          status: 200,
          headers: {
            'Access-Control-Allow-Origin': '*',
            'Content-Type': 'application/json; charset=utf-8'
          },
          body: readText(filePath)
        });
        return;
      }
    }

    request.continue();
  });

  await page.goto(`${origin}/tool/screenshot.html`, {
    waitUntil: 'domcontentloaded'
  });
  await page.addScriptTag({
    path: path.join(ECHARTS_ROOT, 'dist', 'echarts.js')
  });
  await page.addScriptTag({
    path: path.join(
      ORIGINAL_ROOT,
      'node_modules',
      'jquery',
      'dist',
      'jquery.min.js'
    )
  });
  await page.addScriptTag({
    path: path.join(
      ORIGINAL_ROOT,
      'node_modules',
      'lodash',
      'lodash.min.js'
    )
  });
  await page.addScriptTag({
    path: path.join(ECHARTS_ROOT, 'dist', 'extension', 'dataTool.js')
  });
  await page.addScriptTag({
    path: path.join(
      ORIGINAL_ROOT,
      'node_modules',
      'echarts-stat',
      'dist',
      'ecStat.js'
    )
  });

  return {
    browser,
    page,
    rootServer,
    origin
  };
}

async function renderOriginalSvgBrowser(context, filePath, option) {
  const sourceRoot = path.join(ORIGINAL_ROOT, 'public', 'examples', 'ts');
  const exampleId = toPosixRel(ORIG_EXAMPLES_DIR, filePath).replace(/\.json$/, '');
  const sourcePath = resolveOriginalSourcePath(exampleId);
  const sourceText = sourcePath ? readText(sourcePath) : '';
  const currentExamplePath = resolveCurrentExampleJsonPath(exampleId);
  const compiledJsPath = currentExamplePath || !sourcePath ? null : getOriginalCompiledJsPath(sourceRoot, sourcePath);
  const needGl = exampleId.startsWith('gl/');
  const needBMap = /\bbmap\b/.test(sourceText);
  const width = Number(option.width) || SVG_WIDTH;
  const height = Number(option.height) || SVG_HEIGHT;

  await context.page.evaluate(() => {
    document.body.innerHTML = '<div id="viewport"></div>';
    if (window.myChart && typeof window.myChart.dispose === 'function') {
      try {
        window.myChart.dispose();
      } catch (_err) {}
    }
    window.app = {};
  });

  await context.page.evaluate((rootPath, width, height) => {
    window.ROOT_PATH = rootPath;
    window.CDN_PATH = 'https://fastly.jsdelivr.net/npm/';
    const viewport = document.getElementById('viewport');
    viewport.style.width = `${width}px`;
    viewport.style.height = `${height}px`;
    window.myChart = window.echarts.init(viewport, null, {
      renderer: 'svg',
      width,
      height
    });
  }, `${context.origin}/public`, width, height);

  if (needGl) {
    await context.page.addScriptTag({
      path: path.join(
        ORIGINAL_ROOT,
        'node_modules',
        'echarts-gl',
        'dist',
        'echarts-gl.js'
      )
    });
  }

  await preloadBuiltinMaps(context.page, sourceText);

  if (needBMap) {
    await context.page.addScriptTag({
      path: path.join(ECHARTS_ROOT, 'dist', 'extension', 'bmap.js')
    });
  }

  if (compiledJsPath && fs.existsSync(compiledJsPath)) {
    await context.page.addScriptTag({
      path: compiledJsPath
    });
  }

  const svg = await context.page.evaluate((opt, useDirectOption, topFields) => {
    if (useDirectOption) {
      if (Array.isArray(opt.maps)) {
        for (const m of opt.maps) {
          if (m && m.name && m.geoJSON) {
            window.echarts.registerMap(m.name, m.geoJSON);
          }
        }
      }
      const cleanedOption = {};
      for (const [key, value] of Object.entries(opt)) {
        if (!topFields.includes(key)) {
          cleanedOption[key] = value;
        }
      }
      window.myChart.setOption(cleanedOption, true);
    }
    return window.myChart.renderToSVGString();
  }, option, !compiledJsPath, MOONBIT_TOP_FIELDS);

  return svg;
}

function collectOrigJsonFiles(patterns) {
  const files = walkFiles(ORIG_EXAMPLES_DIR, ['.json']);
  if (!patterns || patterns.length === 0) {
    return files;
  }
  return files.filter((filePath) => {
    const id = toPosixRel(ORIG_EXAMPLES_DIR, filePath).replace(/\.json$/, '');
    return patterns.some((pattern) => minimatch(id, pattern));
  });
}

async function compareOrigExamples(patterns, skipExisting) {
  ensureDir(TMP_ORIG_SVG_DIR);
  ensureDir(TMP_MBT_SVG_DIR);
  ensureDir(TMP_ROOT);

  const files = collectOrigJsonFiles(patterns);
  const report = [];
  const mismatched = [];
  const browserContext = await createOriginalBrowserRenderer();

  try {
    for (const filePath of files) {
      const id = toPosixRel(ORIG_EXAMPLES_DIR, filePath).replace(/\.json$/, '');
      const currentExamplePath = resolveCurrentExampleJsonPath(id);
      const optionText = readText(currentExamplePath || filePath);
      let option;
      try {
        option = JSON.parse(optionText);
      } catch (err) {
        report.push({
          id,
          source: toPosixRel(CURRENT_ROOT, filePath),
          status: 'json-parse-failed',
          error: String(err && err.message ? err.message : err)
        });
        continue;
      }

      const originalSvgPath = path.join(TMP_ORIG_SVG_DIR, `${id}.svg`);
      const moonSvgPath = path.join(TMP_MBT_SVG_DIR, `${id}.svg`);
      let originalSvg;
      let moonSvg;

      if (
        skipExisting &&
        fs.existsSync(originalSvgPath) &&
        fs.existsSync(moonSvgPath)
      ) {
        originalSvg = readText(originalSvgPath);
        moonSvg = readText(moonSvgPath);
      } else {
        try {
          originalSvg = await renderOriginalSvgBrowser(
            browserContext,
            filePath,
            option
          );
          writeUtf8(originalSvgPath, `${originalSvg}\n`);
        } catch (err) {
          report.push({
            id,
            source: toPosixRel(CURRENT_ROOT, filePath),
            status: 'original-render-failed',
            error: String(err && err.message ? err.message : err)
          });
          continue;
        }

        const moonRender = renderMoonSvg(optionText);
        if (!moonRender.ok) {
          report.push({
            id,
            source: toPosixRel(CURRENT_ROOT, filePath),
            status: 'moon-render-failed',
            error: moonRender.stderr || moonRender.raw
          });
          continue;
        }

        moonSvg = moonRender.svg;
        writeUtf8(moonSvgPath, `${moonSvg}\n`);
      }

      const same = normalizeSvg(originalSvg) === normalizeSvg(moonSvg);
      const status = same ? 'match' : 'diff';
      if (!same) {
        mismatched.push(id);
      }
      report.push({
        id,
        source: toPosixRel(CURRENT_ROOT, filePath),
        status,
        originalSvg: toPosixRel(CURRENT_ROOT, originalSvgPath),
        moonSvg: toPosixRel(CURRENT_ROOT, moonSvgPath)
      });
      process.stdout.write(`${status} ${id}\n`);
    }

    writeUtf8(TMP_REPORT_PATH, `${JSON.stringify(report, null, 2)}\n`);
    writeREADME(report);
    return {
      report,
      mismatched
    };
  } finally {
    await browserContext.page.close();
    await browserContext.browser.close();
    await new Promise((resolve) => browserContext.rootServer.close(resolve));
  }
}

function groupByStatus(report) {
  const grouped = new Map();
  for (const item of report) {
    const key = item.status || 'unknown';
    if (!grouped.has(key)) {
      grouped.set(key, []);
    }
    grouped.get(key).push(item);
  }
  return grouped;
}

function groupFailureReasons(report) {
  const grouped = new Map();
  for (const item of report) {
    if (item.status !== 'original-render-failed') {
      continue;
    }
    const key = item.error || 'unknown';
    if (!grouped.has(key)) {
      grouped.set(key, []);
    }
    grouped.get(key).push(item);
  }
  return grouped;
}

function writeREADME(report) {
  ensureDir(ORIG_EXAMPLES_DIR);
  const grouped = groupByStatus(report);
  const statusOrder = [
    'match',
    'diff',
    'exported',
    'export-failed',
    'original-render-failed',
    'moon-render-failed',
    'json-parse-failed'
  ];
  const lines = [];
  lines.push('# Original Examples Compatibility');
  lines.push('');
  lines.push('This directory contains original ECharts example options exported from `E:\\recharts\\echarts-examples`.');
  lines.push('The comparison report below records whether the original ECharts renderer and the MoonBit renderer both produced SVG successfully.');
  lines.push('Exact visual parity still needs manual inspection for `diff` entries.');
  lines.push('');
  lines.push('## Summary');
  lines.push('');
  for (const key of statusOrder) {
    const items = grouped.get(key) || [];
    if (items.length > 0) {
      lines.push(`- ${key}: ${items.length}`);
    }
  }
  lines.push('');

  for (const key of statusOrder) {
    const items = grouped.get(key) || [];
    if (items.length === 0) {
      continue;
    }
    lines.push(`## ${key}`);
    lines.push('');
    for (const item of items) {
      lines.push(`- \`${item.id}\` - ${item.source}`);
    }
    lines.push('');
  }

  const failureReasons = groupFailureReasons(report);
  if (failureReasons.size > 0) {
    lines.push('## Failure Reasons');
    lines.push('');
    for (const [reason, items] of [...failureReasons.entries()].sort(
      (a, b) => b[1].length - a[1].length
    )) {
      lines.push(`- ${reason}: ${items.length}`);
    }
    lines.push('');
  }

  lines.push('## Notes');
  lines.push('');
  lines.push('- `match` means the normalized SVG output matched exactly.');
  lines.push('- `diff` means both renderers succeeded, but the normalized SVG strings differed.');
  lines.push('- `export-failed`, `original-render-failed`, and `moon-render-failed` mean the pipeline stopped before a comparable SVG pair was produced.');
  lines.push('- `series.render is required.` and `parametricEquation.x is not a function` are plain-JSON limits: those examples depend on function-valued callbacks from the original example source.');
  lines.push('- `zr.painter.isSingleCanvas is not a function` is a GL/canvas-path gap in the current SVG-only comparison setup.');
  lines.push('- `Invalid data provider.` usually means the example depends on non-JSON runtime data registration or provider logic that is not captured by the exported option alone.');
  lines.push('- `Cannot read properties of undefined (reading \'CHANGABLE_METHODS\')` points to missing runtime helper state from the original example page.');
  lines.push('');

  writeUtf8(README_PATH, `${lines.join('\n')}`);
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    printHelp();
    return;
  }

  if (args.command === 'export') {
    const results = await exportOrigExamples(args.patterns, args.compile);
    writeUtf8(
      path.join(TMP_ROOT, 'export-report.json'),
      `${JSON.stringify(results, null, 2)}\n`
    );
    return;
  }

  if (args.command === 'compare') {
    await compareOrigExamples(args.patterns, args.skipExisting);
    return;
  }

  const exportResults = await exportOrigExamples(args.patterns, args.compile);
  writeUtf8(
    path.join(TMP_ROOT, 'export-report.json'),
    `${JSON.stringify(exportResults, null, 2)}\n`
  );
  await compareOrigExamples(args.patterns, args.skipExisting);
}

main().catch((err) => {
  process.stderr.write(`${err.stack || err}\n`);
  process.exitCode = 1;
});
