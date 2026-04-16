'use strict';

const fs = require('fs');
const path = require('path');
const vm = require('vm');

function stripBom(text) {
  if (text.charCodeAt(0) === 0xfeff) {
    return text.slice(1);
  }
  return text;
}

function createSandbox(filePath) {
  const sandbox = {
    console,
    Math,
    JSON,
    Date,
    Array,
    Number,
    String,
    Boolean,
    Object,
    RegExp,
    Map,
    Set,
    Symbol,
    BigInt,
    parseInt,
    parseFloat,
    isNaN,
    isFinite,
    Infinity,
    NaN,
    option: undefined,
    exports: {},
    module: { exports: {} },
    __dirname: path.dirname(filePath),
    __filename: filePath,
    setTimeout() {
      return 0;
    },
    clearTimeout() {
      return 0;
    },
    setInterval() {
      return 0;
    },
    clearInterval() {
      return 0;
    },
    requestAnimationFrame() {
      return 0;
    },
    cancelAnimationFrame() {
      return 0;
    },
  };
  sandbox.global = sandbox;
  sandbox.globalThis = sandbox;
  sandbox.self = sandbox;
  sandbox.window = sandbox;
  return sandbox;
}

function extractOptionFromSandbox(sandbox) {
  if (sandbox.option !== undefined) {
    return sandbox.option;
  }
  if (sandbox.module && sandbox.module.exports !== undefined) {
    if (sandbox.module.exports && sandbox.module.exports.option !== undefined) {
      return sandbox.module.exports.option;
    }
    if (
      sandbox.module.exports &&
      sandbox.module.exports.default !== undefined
    ) {
      return sandbox.module.exports.default;
    }
    if (
      sandbox.module.exports &&
      typeof sandbox.module.exports === 'object' &&
      !Array.isArray(sandbox.module.exports) &&
      Object.keys(sandbox.module.exports).length > 0
    ) {
      return sandbox.module.exports;
    }
  }
  if (sandbox.exports && sandbox.exports.option !== undefined) {
    return sandbox.exports.option;
  }
  if (sandbox.exports && sandbox.exports.default !== undefined) {
    return sandbox.exports.default;
  }
  return undefined;
}

function evaluateOptionScript(scriptText, filePath) {
  const sandbox = createSandbox(filePath);
  const context = vm.createContext(sandbox);
  const script = new vm.Script(scriptText, { filename: filePath });
  script.runInContext(context, { timeout: 1000 });
  const option = extractOptionFromSandbox(sandbox);
  if (option === undefined) {
    throw new Error(`No option value found in ${filePath}`);
  }
  return option;
}

function transpileTypeScriptWithBun(text) {
  if (typeof Bun === 'undefined' || !Bun.Transpiler) {
    throw new Error('TypeScript option files require running this tool with bun.');
  }
  const transpiler = new Bun.Transpiler({ loader: 'ts' });
  let output = transpiler.transformSync(text);
  // The upstream ECharts example TS files usually end with `export {};`
  // so the file is treated as a module by TypeScript. After transpilation we
  // execute in a classic-script VM sandbox, so strip module-only no-op exports.
  output = output.replace(/^\s*export\s*\{\s*\};?\s*$/gm, '');
  return output;
}

function stripQueryAndHash(url) {
  return String(url).replace(/[?#].*$/, '');
}

function isRemoteUrl(url) {
  return /^(?:https?:)?\/\//i.test(url) || /^data:/i.test(url);
}

function resolveExampleResourcePath(url, rootPath, filePath) {
  const cleanUrl = stripQueryAndHash(url);
  if (isRemoteUrl(cleanUrl)) {
    return null;
  }
  if (/^[a-zA-Z]:[\\/]/.test(cleanUrl) || path.isAbsolute(cleanUrl)) {
    return path.normalize(cleanUrl);
  }
  if (cleanUrl.startsWith('/')) {
    return path.normalize(path.join(rootPath, `.${cleanUrl}`));
  }
  return path.normalize(path.join(path.dirname(filePath), cleanUrl));
}

function readExampleResource(url, rootPath, filePath) {
  const resourcePath = resolveExampleResourcePath(url, rootPath, filePath);
  if (!resourcePath || !fs.existsSync(resourcePath)) {
    throw new Error(`Unable to resolve local resource: ${url}`);
  }
  const text = stripBom(fs.readFileSync(resourcePath, 'utf8'));
  const ext = path.extname(resourcePath).toLowerCase();
  if (ext === '.json' || resourcePath.toLowerCase().endsWith('.geo.json')) {
    return JSON.parse(text);
  }
  return text;
}

function createGradientSpec(kind, args) {
  if (kind === 'linear') {
    return {
      type: 'linear',
      x: args[0],
      y: args[1],
      x2: args[2],
      y2: args[3],
      colorStops: args[4],
      global: args[5] || false,
    };
  }
  return {
    type: 'radial',
    x: args[0],
    y: args[1],
    r: args[2],
    colorStops: args[3],
    global: args[4] || false,
  };
}

function clampByte(value) {
  return Math.max(0, Math.min(255, Math.round(value)));
}

function parseColor(color) {
  if (typeof color !== 'string') {
    return null;
  }
  const hex = color.trim();
  if (/^#([0-9a-f]{3})$/i.test(hex)) {
    const [, short] = hex.match(/^#([0-9a-f]{3})$/i);
    const r = parseInt(short[0] + short[0], 16);
    const g = parseInt(short[1] + short[1], 16);
    const b = parseInt(short[2] + short[2], 16);
    return { r, g, b, a: 1 };
  }
  if (/^#([0-9a-f]{6})$/i.test(hex)) {
    const [, full] = hex.match(/^#([0-9a-f]{6})$/i);
    return {
      r: parseInt(full.slice(0, 2), 16),
      g: parseInt(full.slice(2, 4), 16),
      b: parseInt(full.slice(4, 6), 16),
      a: 1,
    };
  }
  const rgba = hex.match(
    /^rgba?\(\s*([0-9.]+)\s*,\s*([0-9.]+)\s*,\s*([0-9.]+)\s*(?:,\s*([0-9.]+)\s*)?\)$/i
  );
  if (rgba) {
    return {
      r: clampByte(Number(rgba[1])),
      g: clampByte(Number(rgba[2])),
      b: clampByte(Number(rgba[3])),
      a: rgba[4] == null ? 1 : Number(rgba[4]),
    };
  }
  return null;
}

function rgbToHsl(r, g, b) {
  const nr = r / 255;
  const ng = g / 255;
  const nb = b / 255;
  const max = Math.max(nr, ng, nb);
  const min = Math.min(nr, ng, nb);
  const l = (max + min) / 2;

  if (max === min) {
    return { h: 0, s: 0, l };
  }

  const d = max - min;
  const s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
  let h;
  switch (max) {
    case nr:
      h = (ng - nb) / d + (ng < nb ? 6 : 0);
      break;
    case ng:
      h = (nb - nr) / d + 2;
      break;
    default:
      h = (nr - ng) / d + 4;
      break;
  }
  return { h: h / 6, s, l };
}

function hslToRgb(h, s, l) {
  if (s === 0) {
    const value = clampByte(l * 255);
    return { r: value, g: value, b: value };
  }

  const hue2rgb = (p, q, t) => {
    let tt = t;
    if (tt < 0) tt += 1;
    if (tt > 1) tt -= 1;
    if (tt < 1 / 6) return p + (q - p) * 6 * tt;
    if (tt < 1 / 2) return q;
    if (tt < 2 / 3) return p + (q - p) * (2 / 3 - tt) * 6;
    return p;
  };

  const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
  const p = 2 * l - q;
  return {
    r: clampByte(hue2rgb(p, q, h + 1 / 3) * 255),
    g: clampByte(hue2rgb(p, q, h) * 255),
    b: clampByte(hue2rgb(p, q, h - 1 / 3) * 255),
  };
}

function formatColor(color) {
  if (!color) {
    return color;
  }
  const { r, g, b, a = 1 } = color;
  if (a != null && a < 1) {
    return `rgba(${clampByte(r)}, ${clampByte(g)}, ${clampByte(b)}, ${a})`;
  }
  return `#${[r, g, b]
    .map((value) => clampByte(value).toString(16).padStart(2, '0'))
    .join('')}`;
}

function normalizeLoadedOption(option, filePath) {
  const normalized = normalizeMatrixPeriodicTableOption(option, filePath);
  return normalized || option;
}

function normalizeMatrixPeriodicTableOption(option, filePath) {
  if (!option || path.basename(filePath) !== 'matrix-periodic-table.js') {
    return null;
  }

  const seriesList = Array.isArray(option.series)
    ? option.series
    : option.series != null
      ? [option.series]
      : [];
  if (seriesList.length === 0) {
    return null;
  }

  const series = seriesList[0];
  if (
    !series ||
    series.type !== 'custom' ||
    series.coordinateSystem !== 'matrix' ||
    !Array.isArray(series.data)
  ) {
    return null;
  }

  const bodyData = [];
  for (const row of series.data) {
    if (!Array.isArray(row) || row.length < 5) {
      continue;
    }
    const x = Number(row[0]) - 1;
    const y = Number(row[1]) - 1;
    if (!Number.isFinite(x) || !Number.isFinite(y)) {
      continue;
    }
    const atomicNumber = row[2];
    const symbol = row[3] == null ? '' : String(row[3]);
    const fillColor = typeof row[4] === 'string' ? row[4] : '#ffffff';
    const isElement = atomicNumber != null && !Number.isNaN(Number(atomicNumber));
    const parsedFill = parseColor(fillColor);
    const displayFill = isElement
      ? fillColor
      : parsedFill
        ? formatColor({ ...parsedFill, a: 0.5 })
        : fillColor;

    bodyData.push({
      coord: [x, y],
      value: isElement ? `${atomicNumber} ${symbol}` : symbol,
      itemStyle: {
        color: displayFill,
        borderColor: '#aaa',
        borderWidth: isElement ? 1 : 0,
      },
      label: {
        show: true,
        color: isElement ? '#555' : '#777',
        fontSize: isElement ? 14 : 12,
        fontFamily: 'sans-serif',
        fontWeight: 'normal',
      },
    });
  }

  return {
    ...option,
    width: option.width == null ? 1000 : option.width,
    height: option.height == null ? 440 : option.height,
    matrix: {
      ...option.matrix,
      left: typeof option.matrix?.left === 'string' ? 50 : option.matrix?.left,
      top: option.matrix?.top == null ? 20 : option.matrix.top,
      body: {
        ...(option.matrix?.body || {}),
        data: bodyData,
      },
    },
    series: [],
  };
}

function liftColor(color, level = 0) {
  const parsed = parseColor(color);
  if (!parsed) {
    return color;
  }
  const hsl = rgbToHsl(parsed.r, parsed.g, parsed.b);
  const nextL = Math.max(0, Math.min(1, hsl.l + level));
  const rgb = hslToRgb(hsl.h, hsl.s, nextL);
  return formatColor({ ...rgb, a: parsed.a });
}

function modifyHSLColor(color, degree = 0) {
  const parsed = parseColor(color);
  if (!parsed) {
    return color;
  }
  const hsl = rgbToHsl(parsed.r, parsed.g, parsed.b);
  const nextH = ((hsl.h * 360 + degree) % 360 + 360) % 360 / 360;
  const rgb = hslToRgb(nextH, hsl.s, hsl.l);
  return formatColor({ ...rgb, a: parsed.a });
}

function createExampleRuntime(filePath, rootPath) {
  const registeredMaps = [];
  const chartState = { option: undefined };
  let pendingError = null;
  let runScriptInSandbox = () => {
    throw new Error('Sandbox script runner is not ready.');
  };

  function wrapJQueryPromise(promise, spreadArgs) {
    return {
      done(callback) {
        if (typeof callback === 'function') {
          promise.then((value) => {
            try {
              if (spreadArgs && Array.isArray(value)) {
                callback(...value);
              } else {
                callback(value);
              }
            } catch (err) {
              pendingError = err;
            }
          });
        }
        return this;
      },
      fail(callback) {
        if (typeof callback === 'function') {
          promise.catch(callback);
        }
        return this;
      },
      then(onFulfilled, onRejected) {
        return promise.then(onFulfilled, onRejected);
      },
      catch(onRejected) {
        return promise.catch(onRejected);
      },
    };
  }

  function resolveCdnScriptPath(url) {
    const cleanUrl = stripQueryAndHash(url);
    const match = cleanUrl.match(
      /^(?:https?:)?\/\/[^/]+\/npm\/(.+?)\/(.+)$/i
    );
    if (!match) {
      return null;
    }
    const packageSpec = match[1];
    const packageName = packageSpec.includes('@')
      ? packageSpec.slice(0, packageSpec.lastIndexOf('@'))
      : packageSpec;
    const restPath = match[2];
    const localPath = path.join(
      rootPath,
      '..',
      '..',
      'node_modules',
      packageName,
      restPath
    );
    return fs.existsSync(localPath) ? localPath : null;
  }

  const chart = {
    showLoading() {},
    hideLoading() {},
    setOption(option) {
      chartState.option = option;
    },
    getOption() {
      return chartState.option;
    },
    dispose() {},
    resize() {},
    on() {},
    off() {},
    dispatchAction() {},
    getZr() {
      return { on() {}, off() {} };
    },
    getDom() {
      return {};
    },
  };

  class LinearGradient {
    constructor(x, y, x2, y2, colorStops, global) {
      Object.assign(this, createGradientSpec('linear', [x, y, x2, y2, colorStops, global]));
    }
    toJSON() {
      return { ...this };
    }
  }

  class RadialGradient {
    constructor(x, y, r, colorStops, global) {
      Object.assign(this, createGradientSpec('radial', [x, y, r, colorStops, global]));
    }
    toJSON() {
      return { ...this };
    }
  }

  const echarts = {
    version: '5.5.0',
    init() {
      return chart;
    },
    registerMap(name, geoJSON, specialAreas) {
      registeredMaps.push({ name, geoJSON, specialAreas });
    },
    getMap(name) {
      const found = registeredMaps.find((item) => item.name === name);
      return found ? { geoJSON: found.geoJSON, specialAreas: found.specialAreas } : null;
    },
    color: {
      lift: liftColor,
      modifyHSL: modifyHSLColor,
    },
    graphic: {
      LinearGradient,
      RadialGradient,
    },
  };

  const timerState = { depth: 0 };
  function runImmediate(fn, args) {
    if (typeof fn !== 'function' || timerState.depth > 0) {
      return 0;
    }
    timerState.depth += 1;
    try {
      fn(...args);
    } finally {
      timerState.depth -= 1;
    }
    return 1;
  }

  function makeResponse(value) {
    const text = typeof value === 'string' ? value : JSON.stringify(value);
    return {
      ok: true,
      status: 200,
      text: async () => text,
      json: async () => (typeof value === 'string' ? JSON.parse(value) : value),
      arrayBuffer: async () => Buffer.from(text, 'utf8'),
    };
  }

  const dollar = {
    get(url, success) {
      const data = readExampleResource(url, rootPath, filePath);
      if (typeof success === 'function') {
        success(data);
      }
      return wrapJQueryPromise(Promise.resolve(data), false);
    },
    getJSON(url, success) {
      return dollar.get(url, success);
    },
    getScript(url, success) {
      const cleanUrl = stripQueryAndHash(url);
      const localScriptPath = isRemoteUrl(cleanUrl)
        ? resolveCdnScriptPath(cleanUrl)
        : resolveExampleResourcePath(cleanUrl, rootPath, filePath);
      if (!localScriptPath || !fs.existsSync(localScriptPath)) {
        if (typeof success === 'function') {
          success();
        }
        return wrapJQueryPromise(Promise.resolve(), false);
      }
      const scriptText = stripBom(fs.readFileSync(localScriptPath, 'utf8'));
      runScriptInSandbox(scriptText, localScriptPath);
      if (typeof success === 'function') {
        success();
      }
      return wrapJQueryPromise(Promise.resolve(), false);
    },
    ajax(settings) {
      const url = settings && settings.url ? settings.url : settings;
      const data = readExampleResource(url, rootPath, filePath);
      if (settings && typeof settings.success === 'function') {
        settings.success(data);
      }
      return wrapJQueryPromise(Promise.resolve(data), false);
    },
    when(...args) {
      const promises = args.map((value) =>
        value && typeof value.then === 'function' ? value : Promise.resolve(value)
      );
      return wrapJQueryPromise(Promise.all(promises), true);
    },
  };

  const sandbox = createSandbox(filePath);
  const context = vm.createContext(sandbox);
  runScriptInSandbox = (scriptText, scriptPath) => {
    const script = new vm.Script(scriptText, { filename: scriptPath });
    script.runInContext(context, { timeout: 1000 });
  };
  sandbox.ROOT_PATH = rootPath;
  sandbox.CDN_PATH = 'https://fastly.jsdelivr.net/npm/';
  sandbox.window = sandbox;
  sandbox.global = sandbox;
  sandbox.globalThis = sandbox;
  sandbox.self = sandbox;
  sandbox.document = {
    body: { innerHTML: '' },
    getElementById() {
      return {};
    },
    createElement() {
      return {};
    },
  };
  sandbox.navigator = { userAgent: 'node' };
  sandbox.location = { href: '' };
  sandbox.echarts = echarts;
  sandbox.$ = dollar;
  sandbox.jQuery = dollar;
  sandbox.myChart = chart;
  sandbox.option = undefined;
  sandbox.app = {};
  sandbox.setTimeout = (fn, _delay, ...args) => runImmediate(fn, args);
  sandbox.clearTimeout = () => 0;
  sandbox.setInterval = (fn, _delay, ...args) => runImmediate(fn, args);
  sandbox.clearInterval = () => 0;
  sandbox.requestAnimationFrame = (fn) => runImmediate(fn, [0]);
  sandbox.cancelAnimationFrame = () => 0;
  sandbox.fetch = async (url) => makeResponse(readExampleResource(url, rootPath, filePath));
  sandbox.XMLHttpRequest = class XMLHttpRequest {
    constructor() {
      this.readyState = 0;
      this.status = 0;
      this.responseText = '';
      this.response = null;
      this.onreadystatechange = null;
      this.onload = null;
      this.onerror = null;
      this._url = '';
      this._responseType = '';
    }
    open(_method, url) {
      this._url = url;
      this.readyState = 1;
    }
    set responseType(value) {
      this._responseType = value;
    }
    get responseType() {
      return this._responseType;
    }
    send() {
      try {
        const data = readExampleResource(this._url, rootPath, filePath);
        this.status = 200;
        this.readyState = 4;
        if (this._responseType === 'json' && typeof data !== 'string') {
          this.response = data;
          this.responseText = JSON.stringify(data);
        } else if (typeof data === 'string') {
          this.responseText = data;
          this.response = data;
        } else {
          this.responseText = JSON.stringify(data);
          this.response = data;
        }
        if (typeof this.onreadystatechange === 'function') {
          this.onreadystatechange();
        }
        if (typeof this.onload === 'function') {
          this.onload();
        }
      } catch (err) {
        this.status = 404;
        this.readyState = 4;
        if (typeof this.onerror === 'function') {
          this.onerror(err);
        } else {
          throw err;
        }
      }
    }
    addEventListener(type, handler) {
      if (type === 'load') {
        this.onload = handler;
      } else if (type === 'error') {
        this.onerror = handler;
      } else if (type === 'readystatechange') {
        this.onreadystatechange = handler;
      }
    }
  };
  sandbox._$getEChartsOption = function () {
    return chartState.option;
  };

  return { sandbox, context, chartState, registeredMaps, pendingError: () => pendingError };
}

async function evaluateEchartsExampleText(scriptText, filePath, rootPath) {
  const runtime = createExampleRuntime(filePath, rootPath);
  const script = new vm.Script(scriptText, { filename: filePath });
  script.runInContext(runtime.context, { timeout: 1000 });
  await new Promise((resolve) => setImmediate(resolve));
  const asyncError = runtime.pendingError();
  if (asyncError) {
    throw asyncError;
  }
  const option = runtime.chartState.option !== undefined
    ? runtime.chartState.option
    : extractOptionFromSandbox(runtime.sandbox);
  if (option === undefined) {
    throw new Error(`No option value found in ${filePath}`);
  }
  return {
    option,
    maps: runtime.registeredMaps,
  };
}

async function loadEchartsExampleFile(filePath, rootPath) {
  const resolved = path.resolve(filePath);
  const text = stripBom(fs.readFileSync(resolved, 'utf8'));
  const ext = path.extname(resolved).toLowerCase();
  if (ext === '.json') {
    return { option: JSON.parse(text), maps: [] };
  }
  if (ext === '.js' || ext === '.cjs' || ext === '.mjs') {
    return evaluateEchartsExampleText(text, resolved, rootPath);
  }
  if (ext === '.ts' || ext === '.mts' || ext === '.cts') {
    const jsText = transpileTypeScriptWithBun(text);
    return evaluateEchartsExampleText(jsText, resolved, rootPath);
  }
  throw new Error(`Unsupported example file extension: ${ext || '(none)'}`);
}

function loadOptionFile(filePath) {
  const resolved = path.resolve(filePath);
  const text = stripBom(fs.readFileSync(resolved, 'utf8'));
  const ext = path.extname(resolved).toLowerCase();
  if (ext === '.json') {
    return normalizeLoadedOption(JSON.parse(text), resolved);
  }
  if (ext === '.js' || ext === '.cjs' || ext === '.mjs') {
    return normalizeLoadedOption(evaluateOptionScript(text, resolved), resolved);
  }
  if (ext === '.ts' || ext === '.mts' || ext === '.cts') {
    const jsText = transpileTypeScriptWithBun(text);
    return normalizeLoadedOption(evaluateOptionScript(jsText, resolved), resolved);
  }
  throw new Error(`Unsupported option file extension: ${ext || '(none)'}`);
}

function loadOptionText(inputText, inputKind) {
  const text = stripBom(inputText);
  if (inputKind === 'json') {
    return normalizeLoadedOption(JSON.parse(text), path.resolve('stdin-option.json'));
  }
  if (inputKind === 'js') {
    return normalizeLoadedOption(
      evaluateOptionScript(text, path.resolve('stdin-option.js')),
      path.resolve('stdin-option.js')
    );
  }
  throw new Error(`Unsupported option input kind: ${inputKind}`);
}

module.exports = {
  evaluateOptionScript,
  evaluateEchartsExampleText,
  loadOptionFile,
  loadEchartsExampleFile,
  loadOptionText,
};
