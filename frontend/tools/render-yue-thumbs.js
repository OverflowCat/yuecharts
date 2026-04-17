import fs from 'node:fs/promises';
import fsSync from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';

const require = createRequire(import.meta.url);

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const FRONTEND_ROOT = path.resolve(SCRIPT_DIR, '..');
const PROJECT_ROOT = path.resolve(FRONTEND_ROOT, '..');
const EXAMPLES_ROOT = path.join(PROJECT_ROOT, 'examples');
const OUTPUT_ROOT = path.join(FRONTEND_ROOT, 'public', 'thumbs-yue');
const THUMB_WIDTH = 300;
const THUMB_HEIGHT = 225;
const WEBP_QUALITY = 0.92;

const PUPPETEER_CANDIDATES = [
  'E:/recharts/echarts-examples/node_modules/puppeteer',
  'E:/recharts/echarts/node_modules/puppeteer',
];

const CHROME_CANDIDATES = [
  process.env.CHROME_PATH,
  'C:/Program Files/Google/Chrome/Application/chrome.exe',
  'C:/Program Files (x86)/Google/Chrome/Application/chrome.exe',
];

function resolvePuppeteerModule() {
  for (const candidate of PUPPETEER_CANDIDATES) {
    if (candidate && fsSync.existsSync(candidate)) {
      return require(candidate);
    }
  }
  throw new Error(`Unable to locate puppeteer. Tried: ${PUPPETEER_CANDIDATES.join(', ')}`);
}

function resolveChromeExecutable() {
  for (const candidate of CHROME_CANDIDATES) {
    if (candidate && fsSync.existsSync(candidate)) {
      return candidate;
    }
  }
  return undefined;
}

async function walkSvgFiles(rootDir) {
  const files = [];
  const stack = [rootDir];
  while (stack.length > 0) {
    const dir = stack.pop();
    const entries = await fs.readdir(dir, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        stack.push(fullPath);
        continue;
      }
      const lowerName = entry.name.toLowerCase();
      if (!lowerName.endsWith('.svg')) {
        continue;
      }
      const stat = await fs.stat(fullPath);
      // Skip empty placeholder SVGs. Some generated *.jsgen.svg files are
      // tiny stubs, while the paired *.ref.svg is the real renderable source.
      if (stat.size < 64) {
        continue;
      }
      files.push(fullPath);
    }
  }
  return files.sort((a, b) => a.localeCompare(b));
}

function stripVariantSuffix(baseName) {
  let current = baseName;
  while (true) {
    const next = current.replace(/\.(ref|jsgen|echarts)$/i, '');
    if (next === current) {
      return current;
    }
    current = next;
  }
}

function canonicalThumbId(filePath) {
  const relative = path.relative(EXAMPLES_ROOT, filePath).replace(/\\/g, '/');
  const parts = relative.split('/');
  const fileName = parts.pop();
  const stem = fileName.replace(/\.svg$/i, '');
  const canonicalName = stripVariantSuffix(stem);
  return [...parts, canonicalName].join('/');
}

function sourcePriority(filePath) {
  const lowerName = path.basename(filePath).toLowerCase();
  if (lowerName.endsWith('.jsgen.svg')) return 1;
  if (lowerName.endsWith('.echarts.svg')) return 2;
  return 0;
}

function pickBestSources(files) {
  const selected = new Map();
  for (const filePath of files) {
    const id = canonicalThumbId(filePath);
    const score = sourcePriority(filePath);
    const current = selected.get(id);
    if (!current || score < current.score || (score === current.score && filePath < current.filePath)) {
      selected.set(id, { filePath, score });
    }
  }
  return [...selected.entries()]
    .map(([id, entry]) => ({ id, filePath: entry.filePath, score: entry.score }))
    .sort((a, b) => a.id.localeCompare(b.id));
}

function toBuffer(value) {
  if (Buffer.isBuffer(value)) {
    return value;
  }
  if (value instanceof Uint8Array) {
    return Buffer.from(value);
  }
  if (typeof value === 'string') {
    const trimmed = value.trim();
    if (trimmed.startsWith('data:')) {
      const payload = trimmed.split(',')[1] ?? '';
      return Buffer.from(payload, 'base64');
    }
    return Buffer.from(trimmed, 'base64');
  }
  return Buffer.from(value);
}

function bufferToDataUrl(mimeType, bufferLike) {
  const buffer = toBuffer(bufferLike);
  return `data:${mimeType};base64,${buffer.toString('base64')}`;
}

function sanitizeSvgForStaticRaster(svgText) {
  return svgText
    // ECharts SVG exports often rely on animation-driven clip paths. For
    // static thumbnails we want the final state immediately.
    .replace(/(?:-webkit-)?animation(?:-[a-z-]+)?\s*:[^;]+;?/gi, '')
    .replace(/(?:-webkit-)?transition(?:-[a-z-]+)?\s*:[^;]+;?/gi, '');
}

async function renderSvgToThumbs(page, svgText) {
  const staticSvgText = sanitizeSvgForStaticRaster(svgText);
  const dataUrl = `data:image/svg+xml;base64,${Buffer.from(staticSvgText, 'utf8').toString('base64')}`;
  try {
    return await page.evaluate(
      async ({ dataUrl, width, height, quality }) => {
        const image = new Image();
        image.decoding = 'async';
        const loadPromise = new Promise((resolve, reject) => {
          image.onload = () => resolve(null);
          image.onerror = () => reject(new Error('Failed to decode SVG'));
        });
        image.src = dataUrl;
        await loadPromise;

        const canvas = document.createElement('canvas');
        canvas.width = width;
        canvas.height = height;
        const ctx = canvas.getContext('2d');
        if (!ctx) {
          throw new Error('Canvas 2D context unavailable');
        }
        ctx.imageSmoothingEnabled = true;
        ctx.imageSmoothingQuality = 'high';

        const naturalWidth = image.naturalWidth || width;
        const naturalHeight = image.naturalHeight || height;
        const scale = Math.min(width / naturalWidth, height / naturalHeight);
        const drawWidth = naturalWidth * scale;
        const drawHeight = naturalHeight * scale;
        const dx = (width - drawWidth) / 2;
        const dy = (height - drawHeight) / 2;
        ctx.drawImage(image, dx, dy, drawWidth, drawHeight);

        const png = canvas.toDataURL('image/png');
        const webp = canvas.toDataURL('image/webp', quality);
        if (!webp.startsWith('data:image/webp')) {
          throw new Error('WebP encoding is unavailable in this browser');
        }
        return { png, webp };
      },
      { dataUrl, width: THUMB_WIDTH, height: THUMB_HEIGHT, quality: WEBP_QUALITY },
    );
  } catch (error) {
    console.warn(`SVG image decode failed, using inline DOM fallback: ${error instanceof Error ? error.message : String(error)}`);
    await page.setContent(`<!doctype html>
<html>
  <head>
    <meta charset="UTF-8" />
    <style>
      html, body {
        margin: 0;
        width: ${THUMB_WIDTH}px;
        height: ${THUMB_HEIGHT}px;
        overflow: hidden;
        background: transparent;
      }
      #frame {
        width: ${THUMB_WIDTH}px;
        height: ${THUMB_HEIGHT}px;
        display: flex;
        align-items: center;
        justify-content: center;
        overflow: hidden;
      }
      #frame svg {
        max-width: 100%;
        max-height: 100%;
        width: auto;
        height: auto;
        display: block;
      }
    </style>
  </head>
  <body>
    <div id="frame">${staticSvgText}</div>
  </body>
</html>`);
    const pngBuffer = await page.screenshot({ type: 'png', omitBackground: true });
    const png = bufferToDataUrl('image/png', pngBuffer);
    try {
      const webpBuffer = await page.screenshot({
        type: 'webp',
        omitBackground: true,
        quality: Math.round(WEBP_QUALITY * 100),
      });
      const webp = bufferToDataUrl('image/webp', webpBuffer);
      return { png, webp };
    } catch (_webpError) {
      await page.goto('about:blank');
      const webp = await page.evaluate(
        async ({ pngDataUrl, quality }) => {
          const image = new Image();
          const loadPromise = new Promise((resolve, reject) => {
            image.onload = () => resolve(null);
            image.onerror = () => reject(new Error('Failed to decode PNG fallback'));
          });
          image.src = pngDataUrl;
          await loadPromise;

          const canvas = document.createElement('canvas');
          canvas.width = image.naturalWidth || 1;
          canvas.height = image.naturalHeight || 1;
          const ctx = canvas.getContext('2d');
          if (!ctx) {
            throw new Error('Canvas 2D context unavailable');
          }
          ctx.drawImage(image, 0, 0);
          const result = canvas.toDataURL('image/webp', quality);
          if (!result.startsWith('data:image/webp')) {
            throw new Error('WebP encoding is unavailable in this browser');
          }
          return result;
        },
        { pngDataUrl: png, quality: WEBP_QUALITY },
      );
      return { png, webp };
    }
  }
}

async function writeDataUrl(filePath, dataUrl) {
  const payload = dataUrl.split(',')[1];
  if (!payload) {
    throw new Error(`Invalid data URL for ${filePath}`);
  }
  await fs.mkdir(path.dirname(filePath), { recursive: true });
  await fs.writeFile(filePath, Buffer.from(payload, 'base64'));
}

async function main() {
  const puppeteer = resolvePuppeteerModule();
  const chromeExecutable = resolveChromeExecutable();
  const sourceFiles = await walkSvgFiles(EXAMPLES_ROOT);
  const selectedSources = pickBestSources(sourceFiles);

  if (selectedSources.length === 0) {
    throw new Error(`No SVG sources found under ${EXAMPLES_ROOT}`);
  }

  await fs.mkdir(OUTPUT_ROOT, { recursive: true });

  const browser = await puppeteer.launch({
    headless: true,
    executablePath: chromeExecutable,
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-gpu'],
  });

  const page = await browser.newPage();
  await page.setViewport({
    width: THUMB_WIDTH,
    height: THUMB_HEIGHT,
    deviceScaleFactor: 1,
  });
  await page.goto('about:blank');

  const failures = [];
  let rendered = 0;
  try {
    for (const { id, filePath } of selectedSources) {
      try {
        const svgText = await fs.readFile(filePath, 'utf8');
        const { png, webp } = await renderSvgToThumbs(page, svgText);
        const pngPath = path.join(OUTPUT_ROOT, `${id}.png`);
        const webpPath = path.join(OUTPUT_ROOT, `${id}.webp`);
        await writeDataUrl(pngPath, png);
        await writeDataUrl(webpPath, webp);
        rendered += 1;
        console.log(`rendered ${id}`);
      } catch (error) {
        failures.push({ id, filePath, error });
        console.error(`failed ${id}: ${error instanceof Error ? error.message : String(error)}`);
      }
    }
  } finally {
    await page.close();
    await browser.close();
  }

  console.log(`Rendered ${rendered} preview pairs into ${OUTPUT_ROOT}`);
  if (failures.length > 0) {
    console.error(`Failed ${failures.length} preview(s)`);
    process.exitCode = 1;
  }
}

main().catch((error) => {
  console.error(error instanceof Error ? error.stack || error.message : String(error));
  process.exitCode = 1;
});
