<script lang="ts">
  import { onMount } from 'svelte';
  import { EditorView, basicSetup } from 'codemirror';
  import { EditorState } from '@codemirror/state';
  import { javascript } from '@codemirror/lang-javascript';
  import { json } from '@codemirror/lang-json';
  import { oneDark } from '@codemirror/theme-one-dark';
  import { CHART_LIST } from './chartList.js'; // GL intentionally excluded
  import { createWasmRendererPool, type Renderer } from './wasmRenderer';

  interface ChartItem {
    id: string;
    category: string[];
    title: string;
    titleCN?: string;
    ts?: boolean;
    tags?: string[];
    difficulty?: number;
  }

  interface GalleryGroup { cat: string; items: ChartItem[] }
  type ThumbMode = 'yue-webp' | 'yue-png' | 'echarts-webp' | 'live';

  // ── gallery data ────────────────────────────────────────────────────────
  const UNSUPPORTED_TITLE_KEYWORDS = ['动画', '动态', '百度地图', '2022全国', '大规模', '插件', '扩展', '3D'];
  const EXAMPLE_JS_BASE = `${import.meta.env.BASE_URL}examples/js/`;
  const THUMB_YUE_BASE = `${import.meta.env.BASE_URL}thumbs-yue/`;
  const THUMB_ECHARTS_BASE = `${import.meta.env.BASE_URL}thumbs/`;
  const WASM_GC_URL = `${import.meta.env.BASE_URL}cmd/wasm/wasm-gc.wasm`;
  const WASM_LINEAR_URL = `${import.meta.env.BASE_URL}cmd/wasm/wasm.wasm`;
  const THUMB_WASM_WORKERS = 3;

  const CATEGORY_ORDER = [
    'bar','line','pie','scatter','effectScatter','radar','tree','treemap',
    'sunburst','boxplot','candlestick','heatmap','graph','map','parallel',
    'sankey','funnel','gauge','themeRiver','custom','calendar',
    'geo','lines','pictorialBar','chord','dataset','dataZoom',
    'graphic','rich','matrix',
  ];

  function buildGallery(list: ChartItem[]): GalleryGroup[] {
    const byCategory = new Map<string, ChartItem[]>();
    for (const item of list) {
      const cat = getItemCategory(item);
      if (!byCategory.has(cat)) byCategory.set(cat, []);
      byCategory.get(cat)!.push(item);
    }
    const ordered: GalleryGroup[] = [];
    for (const cat of CATEGORY_ORDER) {
      if (byCategory.has(cat)) { ordered.push({ cat, items: byCategory.get(cat)! }); byCategory.delete(cat); }
    }
    for (const [cat, items] of byCategory) ordered.push({ cat, items });
    return ordered;
  }

  const ALL_CHART_LIST = CHART_LIST as ChartItem[];

  function getItemCategory(item: ChartItem): string {
    return item.category.find((category) => category.trim().length > 0) ?? 'other';
  }

  function getCategoryIconName(category: string): string {
    return category === 'other' ? 'graphic' : category;
  }

  function getItemIconName(item: ChartItem): string {
    return getCategoryIconName(getItemCategory(item));
  }

  function uniqueStrings(values: string[]): string[] {
    return [...new Set(values.filter((v) => v.length > 0))];
  }

  function getYueThumbIdCandidates(item: ChartItem): string[] {
    const rawId = item.id.trim();
    const idLower = rawId.toLowerCase();
    const firstCategory = getItemCategory(item).trim().toLowerCase();
    const prefix = idLower.split('-')[0] ?? '';
    const mapFallbacks: Record<string, string[]> = {
      'map-usa-projection': ['map-usa', 'map-bin', 'map-polygon'],
      'map3d-alcohol-consumption': ['map3d-buildings', 'map3d-wood-map', 'map3d-wood-city', 'geo3d'],
      'geo3d-with-different-height': ['geo3d', 'map3d-buildings'],
    };
    const mapCategoryFallbacks = firstCategory === 'map'
      ? ['map-bin', 'map-polygon', 'map-usa', 'map-hk', 'map-iceland-pie']
      : [];
    const geoCategoryFallbacks = firstCategory === 'geo'
      ? ['geo-choropleth-scatter', 'geo-map-scatter', 'geo-lines']
      : [];

    return uniqueStrings([
      rawId,
      idLower,
      rawId.replace('effectScatter', 'effectscatter'),
      rawId.replace('pictorialBar', 'pictorialbar'),
      prefix,
      firstCategory,
      ...(mapFallbacks[idLower] ?? []),
      ...mapCategoryFallbacks,
      ...geoCategoryFallbacks,
      firstCategory === 'effectscatter' ? 'effectscatter' : '',
      firstCategory === 'pictorialbar' ? 'pictorialbar' : '',
    ]);
  }

  function getStaticThumbCandidates(item: ChartItem, mode: ThumbMode): string[] {
    const yueIds = getYueThumbIdCandidates(item);
    const echartsBase = `${THUMB_ECHARTS_BASE}${item.id}`;
    if (mode === 'yue-png') {
      return [
        ...yueIds.map((id) => `${THUMB_YUE_BASE}${id}.png`),
        ...yueIds.map((id) => `${THUMB_YUE_BASE}${id}.webp`),
      ];
    }
    if (mode === 'echarts-webp') {
      return [`${echartsBase}.webp`];
    }
    return [
      ...yueIds.map((id) => `${THUMB_YUE_BASE}${id}.webp`),
      ...yueIds.map((id) => `${THUMB_YUE_BASE}${id}.png`),
    ];
  }

  function getStaticThumbUrl(item: ChartItem, mode: ThumbMode): string {
    return getStaticThumbCandidates(item, mode)[0];
  }

  function handleStaticThumbError(event: Event, item: ChartItem, mode: ThumbMode) {
    const target = event.currentTarget as HTMLImageElement | null;
    if (!target) return;
    const candidates = getStaticThumbCandidates(item, mode);
    const currentSrc = target.currentSrc || target.src || '';
    let currentIndex = Number(target.dataset.thumbFallbackIndex ?? '-1');
    if (
      Number.isNaN(currentIndex)
      || currentIndex < 0
      || currentIndex >= candidates.length
      || !currentSrc.includes(candidates[currentIndex])
    ) {
      currentIndex = candidates.findIndex((candidate) => currentSrc.includes(candidate));
    }
    const nextIndex = currentIndex + 1;
    if (nextIndex < candidates.length) {
      target.dataset.thumbFallbackIndex = String(nextIndex);
      target.src = candidates[nextIndex];
      return;
    }
    target.onerror = null;
    target.src = `/icons/${getItemIconName(item)}.svg`;
    target.classList.add('card-icon-ph');
  }

  function isUnsupportedExample(item: ChartItem): boolean {
    const title = `${item.titleCN || ''} ${item.title || ''}`;
    return UNSUPPORTED_TITLE_KEYWORDS.some((keyword) => title.includes(keyword));
  }

  function getExampleJsUrl(id: string): string {
    return `${EXAMPLE_JS_BASE}${id}.js`;
  }

  function evaluateExampleJs(code: string): Record<string, unknown> {
    // Support both `option = {...}` and scripts that push the option through
    // `myChart.setOption(...)`, which is the convention used by some upstream
    // example loaders.
    // eslint-disable-next-line no-new-func
    const fn = new Function(`
      var option;
      var __capturedOption;
      var __previousMyChart = window.myChart;
      var __registeredMaps = {};
      function __deepClone(value) {
        if (value == null) return value;
        try {
          return JSON.parse(JSON.stringify(value));
        } catch {
          return value;
        }
      }
      function __toDate(value) {
        var d = new Date(value);
        return Number.isNaN(d.getTime()) ? null : d;
      }
      function __readSync(url, asJson) {
        var raw = String(url || '');
        var lower = raw.toLowerCase();
        if (!raw || lower.startsWith('http://') || lower.startsWith('https://') || raw.startsWith('//')) {
          return asJson ? {} : '';
        }
        try {
          var xhr = new XMLHttpRequest();
          xhr.open('GET', url, false);
          xhr.send(null);
          if (xhr.status >= 200 && xhr.status < 300) {
            if (asJson) {
              try { return JSON.parse(xhr.responseText); } catch { return {}; }
            }
            return xhr.responseText;
          }
        } catch {}
        return asJson ? {} : '';
      }
      function __deferred(value, spreadArgs) {
        return {
          done: function (cb) {
            if (typeof cb === 'function') {
              if (spreadArgs && Array.isArray(value)) cb.apply(null, value);
              else cb(value);
            }
            return this;
          },
          fail: function () { return this; },
          then: function (cb) {
            if (typeof cb === 'function') cb(value);
            return this;
          },
          catch: function () { return this; },
        };
      }
      var $ = {
        get: function (url, success) {
          var data = __readSync(url, false);
          if (typeof success === 'function') success(data);
          return __deferred(data, false);
        },
        getJSON: function (url, success) {
          var data = __readSync(url, true);
          if (typeof success === 'function') success(data);
          return __deferred(data, false);
        },
        getScript: function (url, success) {
          var text = __readSync(url, false);
          if (text) {
            // eslint-disable-next-line no-eval
            eval(text);
          }
          if (typeof success === 'function') success();
          return __deferred(undefined, false);
        },
        ajax: function (settings) {
          var url = settings && settings.url ? settings.url : settings;
          var asJson = settings && settings.dataType === 'json';
          var data = __readSync(url, !!asJson);
          if (settings && typeof settings.success === 'function') settings.success(data);
          return __deferred(data, false);
        },
        when: function () {
          var args = Array.prototype.slice.call(arguments);
          return __deferred(args, true);
        }
      };
      var jQuery = $;
      var echarts = window.echarts || {
        registerMap: function (name, geoJSON, specialAreas) {
          __registeredMaps[name] = { geoJSON: geoJSON, specialAreas: specialAreas };
        },
        getMap: function (name) {
          return __registeredMaps[name] || null;
        },
        registerTheme: function () {},
        registerTransform: function () {},
        registerAction: function () {},
        registerCoordinateSystem: function () {},
        registerProcessor: function () {},
        registerLayout: function () {},
        registerVisual: function () {},
        connect: function () {},
        disconnect: function () {},
        util: {
          clone: function (value) { return __deepClone(value); },
          map: function (arr, cb) { return Array.isArray(arr) ? arr.map(cb) : []; },
          each: function (arr, cb) { if (Array.isArray(arr) && typeof cb === 'function') arr.forEach(cb); }
        },
        number: {
          round: function (value, precision) {
            var p = Math.pow(10, precision || 0);
            return Math.round(Number(value) * p) / p;
          },
          parseDate: function (value) { return __toDate(value) || value; }
        },
        format: {
          addCommas: function (value) {
            var num = Number(value);
            return Number.isFinite(num) ? num.toLocaleString('en-US') : String(value);
          },
          formatTime: function (_tpl, value) {
            var d = __toDate(value);
            return d ? d.toISOString() : String(value);
          }
        },
        time: {
          parse: function (value) { return __toDate(value) || value; },
          parseDate: function (value) { return __toDate(value) || value; },
          format: function (_tpl, value) {
            var d = __toDate(value);
            return d ? d.toISOString() : String(value);
          },
          formatTime: function (_tpl, value) {
            var d = __toDate(value);
            return d ? d.toISOString() : String(value);
          },
          roundTime: function (_unit, value) {
            var d = __toDate(value);
            return d ? d.getTime() : value;
          }
        },
        graphic: {
          LinearGradient: function (x, y, x2, y2, colorStops, global) {
            return { type: 'linear', x: x, y: y, x2: x2, y2: y2, colorStops: colorStops, global: !!global };
          },
          RadialGradient: function (x, y, r, colorStops, global) {
            return { type: 'radial', x: x, y: y, r: r, colorStops: colorStops, global: !!global };
          }
        },
        color: {
          lift: function (value) { return value; },
          modifyHSL: function (value) { return value; }
        }
      };
      var myChart = {
        showLoading: function () {},
        hideLoading: function () {},
        setOption: function (next) {
          __capturedOption = next;
          option = next;
        },
        getOption: function () {
          return __capturedOption ?? option;
        },
        getWidth: function () { return 600; },
        getHeight: function () { return 400; },
        convertToPixel: function () { return [0, 0]; },
        convertFromPixel: function () { return [0, 0]; },
        getZr: function () {
          return { on: function () {}, off: function () {}, configLayer: function () {} };
        },
        on: function () {},
        off: function () {},
        dispatchAction: function () {},
        dispose: function () {},
        resize: function () {}
      };
      var app = {};
      var ecStat = {
        clustering: { hierarchicalKMeans: function (data) { return { data: data || [], centroids: [] }; } },
        regression: function (_type, data) { return { points: data || [], parameter: {}, expression: '' }; },
        histogram: function () { return { bins: [], data: [], customData: [] }; }
      };
      var ROOT_PATH = '${import.meta.env.BASE_URL}examples/data/asset/';
      var CDN_PATH = 'https://fastly.jsdelivr.net/npm/';
      window.myChart = myChart;
      window.$ = $;
      window.jQuery = jQuery;
      window.echarts = echarts;
      var chart = myChart;
      try {
        ${code}
      } finally {
        window.myChart = __previousMyChart;
      }
      return typeof option !== "undefined" ? option : __capturedOption;
    `);
    const opt = fn() as Record<string, unknown> | undefined;
    if (opt == null) throw new Error('No option value found');
    return opt;
  }

  const MOONBIT_TOP_FIELDS = new Set(['width','height','maps']);

  const DEFAULT_JSON = `{
  "width": 600,
  "height": 400,
  "title": { "text": "Weekly Sales" },
  "xAxis": { "type": "category", "data": ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"] },
  "yAxis": { "type": "value" },
  "series": [{ "type": "bar", "name": "Sales", "data": [120,200,150,80,70,110,130] }]
}`;

  const DEFAULT_JS = `// Standard ECharts option format.
// Assign to the 'option' variable.
var option = {
  title: { text: 'Weekly Sales' },
  xAxis: { type: 'category', data: ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'] },
  yAxis: { type: 'value' },
  series: [{ type: 'bar', data: [120, 200, 150, 80, 70, 110, 130] }]
};`;

  // ── app state ────────────────────────────────────────────────────────────
  let page = $state<'gallery' | 'editor'>('gallery');
  let tab = $state<'json' | 'js'>('js');
  let jsonCode = $state(DEFAULT_JSON);
  let jsCode = $state(DEFAULT_JS);
  let jsWidth = $state(600);
  let jsHeight = $state(400);
  let backend = $state<'gc' | 'linear' | 'echarts'>('gc');
  let status = $state('Loading renderers…');
  let statusError = $state(false);
  let svgOutput = $state('');
  let hasSvgOutput = $state(false);
  let rendering = $state(false);
  let conversionError = $state('');

  // gallery thumbnail mode
  let hideUnsupported = $state(true);
  let thumbMode = $state<ThumbMode>('yue-webp');
  let thumbBackend = $state<'gc' | 'linear' | 'echarts'>('gc');

  // cached live thumbnails
  let cardSvg = $state<Record<string, string>>({});
  let cardLoading = $state<Record<string, boolean>>({});
  let thumbGen = 0;

  const optionCache = new Map<string, Record<string, unknown>>();
  const optionPending = new Map<string, Promise<Record<string, unknown> | null>>();

  let renderers = $state<{ gc: Renderer | null; linear: Renderer | null; echarts: Renderer | null }>({ gc: null, linear: null, echarts: null });
  let avail = $state({ gc: false, linear: false, echarts: false });
  let loadingDone = $state(false);
  let currentExampleId = $state('');
  const thumbRenderers = new Map<'gc' | 'linear', Renderer>();
  const thumbRendererLoads = new Map<'gc' | 'linear', Promise<Renderer>>();

  let echartsContainer = $state<HTMLDivElement | null>(null);
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  let echartsLib: any = null;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  let echartsInst: any = null;
  let renderSeq = 0;

  let jsonEditorEl = $state<HTMLDivElement | null>(null);
  let jsEditorEl = $state<HTMLDivElement | null>(null);
  let jsonEditorView: EditorView | null = null;
  let jsEditorView: EditorView | null = null;
  let gallery = $derived.by(() => {
    const list = hideUnsupported ? ALL_CHART_LIST.filter((item) => !isUnsupportedExample(item)) : ALL_CHART_LIST;
    return buildGallery(list);
  });

  // ── wasm loaders ─────────────────────────────────────────────────────────
  async function loadWasmGC(): Promise<Renderer> {
    return await createWasmRendererPool('gc', WASM_GC_URL, 1);
  }

  async function loadWasmLinear(): Promise<Renderer> {
    return await createWasmRendererPool('linear', WASM_LINEAR_URL, 1);
  }

  async function loadEChartsRenderer(): Promise<Renderer> {
    await new Promise<void>((resolve, reject) => {
      const s = document.createElement('script');
      s.src = 'https://cdn.jsdelivr.net/npm/echarts@6.0.0/dist/echarts.min.js';
      s.onload = () => resolve();
      s.onerror = () => reject(new Error('Failed to load echarts.js'));
      document.head.appendChild(s);
    });
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    echartsLib = (window as any).echarts;
    return {
      render: async (json: string) => {
        const raw = JSON.parse(json) as Record<string, unknown>;
        const w = Number(raw['width']) || 600;
        const h = Number(raw['height']) || 400;
        if (Array.isArray(raw['maps'])) {
          for (const m of raw['maps'] as Array<{ name?: string; geoJSON?: unknown }>) {
            if (m.name && m.geoJSON) echartsLib.registerMap(m.name, m.geoJSON);
          }
        }
        echartsContainer!.style.width  = `${w}px`;
        echartsContainer!.style.height = `${h}px`;
        if (!echartsInst) {
          echartsInst = echartsLib.init(echartsContainer, null, { renderer: 'svg', width: w, height: h });
        } else {
          echartsInst.resize({ width: w, height: h });
        }
        const opt: Record<string, unknown> = {};
        for (const [k, v] of Object.entries(raw)) {
          if (!MOONBIT_TOP_FIELDS.has(k)) opt[k] = v;
        }
        opt['animation'] = false;
        echartsInst.setOption(opt, { notMerge: true });
        await new Promise(r => requestAnimationFrame(() => requestAnimationFrame(r)));
        return null;
      },
      version: () => '?',
      dispose: () => {},
    };
  }

  async function getThumbRenderer(backend: 'gc' | 'linear'): Promise<Renderer> {
    const cached = thumbRenderers.get(backend);
    if (cached) return cached;
    const loading = thumbRendererLoads.get(backend);
    if (loading) return loading;
    const wasmUrl = backend === 'gc' ? WASM_GC_URL : WASM_LINEAR_URL;
    const load = createWasmRendererPool(backend, wasmUrl, THUMB_WASM_WORKERS)
      .then((renderer) => {
        thumbRenderers.set(backend, renderer);
        thumbRendererLoads.delete(backend);
        return renderer;
      })
      .catch((error) => {
        thumbRendererLoads.delete(backend);
        throw error;
      });
    thumbRendererLoads.set(backend, load);
    return load;
  }

  // ── init ─────────────────────────────────────────────────────────────────
  onMount(() => {
    let disposed = false;
    const onHashChange = () => { void openFromHash(); };
    window.addEventListener('hashchange', onHashChange);

    void (async () => {
      // CodeMirror — JSON editor (light)
      jsonEditorView = new EditorView({
        state: EditorState.create({
          doc: jsonCode,
          extensions: [
            basicSetup,
            json(),
            EditorView.updateListener.of(u => { if (u.docChanged) jsonCode = u.state.doc.toString(); }),
          ],
        }),
        parent: jsonEditorEl!,
      });

      // CodeMirror — JS editor (dark)
      jsEditorView = new EditorView({
        state: EditorState.create({
          doc: jsCode,
          extensions: [
            basicSetup,
            javascript(),
            oneDark,
            EditorView.updateListener.of(u => { if (u.docChanged) jsCode = u.state.doc.toString(); }),
          ],
        }),
        parent: jsEditorEl!,
      });

      // Load renderers
      const [gcR, linearR, ecR] = await Promise.allSettled([
        loadWasmGC(), loadWasmLinear(), loadEChartsRenderer()
      ]);
      if (disposed) {
        if (gcR.status === 'fulfilled') gcR.value.dispose();
        if (linearR.status === 'fulfilled') linearR.value.dispose();
        if (ecR.status === 'fulfilled') ecR.value.dispose();
        return;
      }
      if (gcR.status === 'fulfilled')     { renderers.gc = gcR.value;        avail.gc = true; }
      if (linearR.status === 'fulfilled') { renderers.linear = linearR.value; avail.linear = true; }
      if (ecR.status === 'fulfilled')     { renderers.echarts = ecR.value;   avail.echarts = true; }

      if (!avail.gc && avail.linear) backend = 'linear';
      if (!avail.gc && !avail.linear && avail.echarts) backend = 'echarts';

      loadingDone = true;
      const anyReady = avail.gc || avail.linear || avail.echarts;
      status = anyReady ? 'Ready' : 'Failed to load any renderer';
      statusError = !anyReady;

      await openFromHash();
    })();

    return () => {
      disposed = true;
      window.removeEventListener('hashchange', onHashChange);
      jsonEditorView?.destroy();
      jsEditorView?.destroy();
      jsonEditorView = null;
      jsEditorView = null;
    };
  });

  // ── JS eval ──────────────────────────────────────────────────────────────
  function evalJSOptionRaw(code: string): Record<string, unknown> {
    return evaluateExampleJs(code);
  }

  function evalJSOption(code: string): string {
    const opt = evalJSOptionRaw(code);
    return JSON.stringify({ width: jsWidth, height: jsHeight, ...opt });
  }

  // ── tab switching with auto-conversion ───────────────────────────────────
  function switchTab(newTab: 'json' | 'js') {
    if (newTab === tab) return;
    conversionError = '';

    if (newTab === 'json' && tab === 'js') {
      try {
        const opt = evalJSOptionRaw(jsCode);
        const jsonObj = { width: jsWidth, height: jsHeight, ...opt };
        const newJson = JSON.stringify(jsonObj, null, 2);
        jsonCode = newJson;
        jsonEditorView?.dispatch({ changes: { from: 0, to: jsonEditorView.state.doc.length, insert: newJson } });
      } catch (e) {
        conversionError = 'JS→JSON failed: ' + (e as Error).message;
      }
    } else if (newTab === 'js' && tab === 'json') {
      try {
        const obj = JSON.parse(jsonCode) as Record<string, unknown>;
        const { width, height, maps, ...option } = obj;
        if (typeof width === 'number') jsWidth = width;
        if (typeof height === 'number') jsHeight = height;
        void maps;
        const newJs = 'var option = ' + JSON.stringify(option, null, 2) + ';';
        jsCode = newJs;
        jsEditorView?.dispatch({ changes: { from: 0, to: jsEditorView.state.doc.length, insert: newJs } });
      } catch (e) {
        conversionError = 'JSON→JS failed: ' + (e as Error).message;
      }
    }

    tab = newTab;
  }

  // ── render ────────────────────────────────────────────────────────────────
  async function onRender() {
    const seq = ++renderSeq;
    clearRenderedOutput();
    const renderer = renderers[backend];
    if (!renderer) { status = 'Backend not available'; statusError = true; return; }

    let json: string;
    try {
      json = tab === 'json' ? jsonCode.trim() : evalJSOption(jsCode);
    } catch (e) {
      status = 'Error: ' + (e as Error).message; statusError = true; return;
    }
    if (!json!) { status = 'Empty input'; statusError = true; return; }
    try { JSON.parse(json!); } catch (e) { status = 'Invalid JSON: ' + (e as Error).message; statusError = true; return; }

    rendering = true;
    statusError = false;
    status = 'Rendering…';
    try {
      const t0 = performance.now();
      const svg = await renderer.render(json!);
      if (seq !== renderSeq) return;
      if (svg !== null) svgOutput = svg;
      hasSvgOutput = Boolean(getCurrentSvgText()?.trim());
      status = `Rendered in ${(performance.now() - t0).toFixed(1)} ms`;
    } catch (e) {
      if (seq !== renderSeq) return;
      status = 'Render error: ' + (e as Error).message; statusError = true;
      hasSvgOutput = Boolean(getCurrentSvgText()?.trim());
      console.error(e);
    } finally {
      if (seq === renderSeq) rendering = false;
    }
  }

  // Clear the visible preview so stale SVG does not survive a failed render.
  function clearRenderedOutput() {
    svgOutput = '';
    hasSvgOutput = false;
    echartsInst?.clear?.();
  }

  function getCurrentSvgText(): string | null {
    if (backend === 'echarts') {
      const svgEl = echartsContainer?.querySelector('svg');
      return svgEl ? svgEl.outerHTML : null;
    }
    return svgOutput || null;
  }

  function buildDownloadFileName(): string {
    const base = currentExampleId || 'chart';
    const safeBase = base.replace(/[^a-zA-Z0-9._-]+/g, '_');
    return `${safeBase}.${backend}.svg`;
  }

  function onDownloadSvg() {
    const svg = getCurrentSvgText();
    if (!svg || !svg.trim()) {
      status = 'No SVG output to download';
      statusError = true;
      return;
    }

    const content = svg.endsWith('\n') ? svg : `${svg}\n`;
    const blob = new Blob([content], { type: 'image/svg+xml;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = buildDownloadFileName();
    document.body.appendChild(a);
    a.click();
    a.remove();
    URL.revokeObjectURL(url);

    status = `Downloaded ${a.download}`;
    statusError = false;
  }

  function getHashExampleId(): string | null {
    if (typeof window === 'undefined') return null;
    const raw = window.location.hash;
    if (!raw || raw === '#') return null;
    const payload = raw.slice(1);
    try {
      return decodeURIComponent(payload);
    } catch {
      return payload;
    }
  }

  function setHashExampleId(id: string) {
    if (typeof window === 'undefined') return;
    const next = `#${encodeURIComponent(id)}`;
    if (window.location.hash === next) return;
    window.history.replaceState(null, '', next);
  }

  function clearHashExampleId() {
    if (typeof window === 'undefined') return;
    if (!window.location.hash) return;
    window.history.replaceState(null, '', window.location.pathname + window.location.search);
  }

  function findExampleById(id: string): ChartItem | undefined {
    return ALL_CHART_LIST.find((item) => item.id === id);
  }

  async function openFromHash() {
    const id = getHashExampleId();
    if (!id) return;
    const item = findExampleById(id);
    if (!item) return;
    if (page === 'editor' && currentExampleId === id) return;
    await openExample(item, { syncHash: false });
  }

  // ── open example ─────────────────────────────────────────────────────────
  async function openExample(item: ChartItem, options?: { syncHash?: boolean }) {
    const syncHash = options?.syncHash ?? true;
    try {
      const res = await fetch(getExampleJsUrl(item.id));
      if (!res.ok) throw new Error(String(res.status));
      const code = await res.text();
      jsCode = code;
      jsEditorView?.dispatch({ changes: { from: 0, to: jsEditorView.state.doc.length, insert: code } });
      jsonCode = '';
      jsonEditorView?.dispatch({ changes: { from: 0, to: jsonEditorView.state.doc.length, insert: '' } });
      tab = 'js';
      currentExampleId = item.id;
      conversionError = '';
      clearRenderedOutput();
      page = 'editor';
      if (syncHash) setHashExampleId(item.id);
      await new Promise(r => setTimeout(r, 10));
      onRender();
    } catch (e) {
      console.error('Failed to load example:', e);
    }
  }

  function newChart() {
    jsCode = DEFAULT_JS;
    jsEditorView?.dispatch({ changes: { from: 0, to: jsEditorView.state.doc.length, insert: DEFAULT_JS } });
    jsonCode = DEFAULT_JSON;
    jsonEditorView?.dispatch({ changes: { from: 0, to: jsonEditorView.state.doc.length, insert: DEFAULT_JSON } });
    jsWidth = 600; jsHeight = 400;
    tab = 'json';
    currentExampleId = '';
    conversionError = '';
    clearRenderedOutput();
    page = 'editor';
    clearHashExampleId();
  }

  // ── live thumbnails ───────────────────────────────────────────────────────
  const THUMB_W = 300;
  const THUMB_H = 225;
  const THUMB_CONCURRENCY = 3;

  let thumbQueue: string[] = [];
  let thumbQueued = new Set<string>();
  let thumbActive = 0;

  let thumbEchartsContainer: HTMLDivElement | null = null;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  let thumbEchartsInst: any = null;

  const yield0 = () => new Promise<void>(r => setTimeout(r, 0));

  async function loadOptionForThumb(id: string): Promise<Record<string, unknown> | null> {
    const cached = optionCache.get(id);
    if (cached) return cached;

    const pending = optionPending.get(id);
    if (pending) return pending;

    const task = (async () => {
      const res = await fetch(getExampleJsUrl(id));
      if (!res.ok) return null;
      const code = await res.text();
      try {
        const opt = evaluateExampleJs(code);
        optionCache.set(id, opt);
        return opt;
      } catch {
        return null;
      }
    })();

    optionPending.set(id, task);
    try {
      return await task;
    } finally {
      optionPending.delete(id);
    }
  }

  function scheduleThumb(id: string) {
    if (cardSvg[id] || cardLoading[id]) return;
    if (thumbQueued.has(id)) return;
    thumbQueue.push(id);
    thumbQueued.add(id);
    drainThumbQueue();
  }

  function drainThumbQueue() {
    while (thumbQueue.length > 0 && thumbActive < THUMB_CONCURRENCY) {
      const id = thumbQueue.shift()!;
      thumbQueued.delete(id);
      if (cardSvg[id] || cardLoading[id]) continue;
      thumbActive++;
      cardLoading = { ...cardLoading, [id]: true };
      renderOneThumb(id).finally(() => {
        thumbActive--;
        cardLoading = { ...cardLoading, [id]: false };
        drainThumbQueue();
      });
    }
  }

  async function renderOneThumb(id: string) {
    // Immediately yield so the UI re-paints before any heavy work.
    await yield0();
    const gen = thumbGen;
    if (gen !== thumbGen) return;
    try {
      const opt = await loadOptionForThumb(id);
      if (!opt) return;
      if (gen !== thumbGen) return;

      if (thumbBackend === 'echarts') {
        if (!echartsLib) return;
        if (!thumbEchartsContainer) {
          thumbEchartsContainer = document.createElement('div');
          thumbEchartsContainer.style.cssText = 'position:absolute;top:-9999px;left:-9999px;pointer-events:none;';
          document.body.appendChild(thumbEchartsContainer);
        }
        thumbEchartsContainer.style.width = THUMB_W + 'px';
        thumbEchartsContainer.style.height = THUMB_H + 'px';
        if (!thumbEchartsInst) {
          thumbEchartsInst = echartsLib.init(thumbEchartsContainer, null, { renderer: 'svg', width: THUMB_W, height: THUMB_H });
        } else {
          thumbEchartsInst.resize({ width: THUMB_W, height: THUMB_H });
        }
        const cleanOpt = { ...opt, animation: false };
        thumbEchartsInst.setOption(cleanOpt, { notMerge: true });
        await new Promise(r => requestAnimationFrame(() => requestAnimationFrame(r)));
        if (gen !== thumbGen) return;
        const svgEl = thumbEchartsContainer.querySelector('svg');
        if (svgEl) cardSvg = { ...cardSvg, [id]: svgEl.outerHTML };
      } else {
        const renderer = await getThumbRenderer(thumbBackend);
        if (!renderer) return;
        const json = JSON.stringify({ width: THUMB_W, height: THUMB_H, ...opt });
        // Yield before dispatching work to a worker so the UI can repaint.
        await yield0();
        if (gen !== thumbGen) return;
        const svg = await renderer.render(json);
        if (gen !== thumbGen) return;
        if (svg) cardSvg = { ...cardSvg, [id]: svg };
      }
    } catch { /* silently ignore */ }
  }

  // Reset caches whenever mode or backend changes.
  $effect(() => {
    void thumbMode;
    void thumbBackend;
    thumbGen++;
    cardSvg = {};
    cardLoading = {};
    thumbQueue = [];
    thumbQueued = new Set();
    thumbActive = 0;
  });

  let thumbObserver: IntersectionObserver | null = null;
  const observedThumbNodes = new Map<string, HTMLElement>();

  function resetThumbObserver() {
    thumbObserver?.disconnect();
    thumbObserver = null;
    observedThumbNodes.clear();
  }

  function ensureThumbObserver() {
    if (thumbObserver) return thumbObserver;
    thumbObserver = new IntersectionObserver(entries => {
      for (const entry of entries) {
        if (!entry.isIntersecting) continue;
        const node = entry.target as HTMLElement;
        const id = node.dataset.thumbId;
        if (!id) continue;
        scheduleThumb(id);
        thumbObserver?.unobserve(node);
        observedThumbNodes.delete(id);
      }
    }, { rootMargin: '300px' });
    return thumbObserver;
  }

  // Svelte action: registers card with a shared IntersectionObserver.
  // Passes mode as parameter so Svelte calls update() when thumbMode changes.
  function lazyThumb(node: HTMLElement, params: { id: string; mode: ThumbMode }) {
    let currentId = params.id;
    node.dataset.thumbId = currentId;

    function unobserveIfAny(id: string) {
      const observed = observedThumbNodes.get(id);
      if (!observed) return;
      thumbObserver?.unobserve(observed);
      observedThumbNodes.delete(id);
    }

    function setup(mode: ThumbMode, id: string) {
      unobserveIfAny(currentId);
      currentId = id;
      node.dataset.thumbId = currentId;
      if (mode !== 'live') return;
      // If already rendered, nothing to do.
      if (cardSvg[id]) return;
      const observer = ensureThumbObserver();
      observedThumbNodes.set(id, node);
      observer.observe(node);
    }

    setup(params.mode, params.id);
    return {
      update(p: { id: string; mode: ThumbMode }) {
        setup(p.mode, p.id);
      },
      destroy() {
        unobserveIfAny(currentId);
      },
    };
  }

  onMount(() => {
    return () => {
      resetThumbObserver();
      for (const renderer of Object.values(renderers)) {
        renderer?.dispose();
      }
      for (const renderer of thumbRenderers.values()) {
        renderer.dispose();
      }
      thumbRenderers.clear();
      thumbRendererLoads.clear();
      if (thumbEchartsInst) {
        thumbEchartsInst.dispose();
        thumbEchartsInst = null;
      }
      if (thumbEchartsContainer) {
        thumbEchartsContainer.remove();
        thumbEchartsContainer = null;
      }
    };
  });
</script>

<!-- ── Always-present but conditionally visible pages ─────────────────── -->

<!-- GALLERY ─────────────────────────────────────────────────────────────── -->
<div class="page gallery-page" style:display={page === 'gallery' ? 'flex' : 'none'}>
  <header>
    <h1>YueCharts</h1>
    <div class="gallery-actions">
      <div class="gallery-actions-left thumb-controls">
        <span class="ctrl-label">Preview:</span>
        <div class="backend-toggle">
          <label class:active={thumbMode === 'yue-webp'}>
            <input type="radio" name="thumbMode" value="yue-webp" bind:group={thumbMode} />
            Yue WebP
          </label>
          <label class:active={thumbMode === 'yue-png'}>
            <input type="radio" name="thumbMode" value="yue-png" bind:group={thumbMode} />
            Yue PNG
          </label>
          <label class:active={thumbMode === 'echarts-webp'}>
            <input type="radio" name="thumbMode" value="echarts-webp" bind:group={thumbMode} />
            ECharts WebP
          </label>
          <label class:active={thumbMode === 'live'}>
            <input type="radio" name="thumbMode" value="live" bind:group={thumbMode} />
            Live SVG
          </label>
        </div>
        {#if thumbMode === 'live'}
          <div class="backend-toggle">
            {#each ([['gc','wasm-gc'],['linear','wasm'],['echarts','echarts.js']] as [keyof typeof avail, string][]) as [val, label]}
              <label class:active={thumbBackend === val} class:unavail={loadingDone && !avail[val]}>
                <input type="radio" name="thumbBackend" value={val}
                  disabled={loadingDone && !avail[val]}
                  bind:group={thumbBackend} />
                {label}
              </label>
            {/each}
          </div>
        {/if}
      </div>
      <button
        class="gallery-actions-right switch-btn"
        class:active={hideUnsupported}
        aria-pressed={hideUnsupported}
        title={hideUnsupported ? '当前隐藏不支持示例' : '当前显示不支持示例'}
        onclick={() => hideUnsupported = !hideUnsupported}
      >
        {hideUnsupported ? '显示不支持的示例' : '隐藏不支持的示例'}
      </button>
    </div>
  </header>

  <div class="gallery-layout">
    <nav class="cat-nav">
      <button class="cat-new-btn" onclick={newChart}>+ New Chart</button>
        {#each gallery as { cat }}
        <a class="cat-nav-item" href={`#cat-${cat}`}>
          <img src={`/icons/${getCategoryIconName(cat)}.svg`} alt=""
            onerror={(e) => { const t = e.currentTarget as HTMLImageElement; t.onerror = null; t.style.visibility = 'hidden'; }} />
          {cat}
        </a>
      {/each}
    </nav>

    <div class="gallery-content">
      <!-- New Chart card -->
      <button class="card card-empty" onclick={newChart}>
        <div class="card-thumb card-thumb-empty">
          <span class="plus-icon">+</span>
          <span>New Chart</span>
        </div>
        <div class="card-title">Start from scratch</div>
      </button>

      {#each gallery as { cat, items }}
        <section id={`cat-${cat}`} class="gallery-section">
          <h2 class="section-head">
            <img src={`/icons/${getCategoryIconName(cat)}.svg`} alt=""
              onerror={(e) => { const t = e.currentTarget as HTMLImageElement; t.onerror = null; t.style.visibility = 'hidden'; }} />
            {cat}
          </h2>
          <div class="card-grid">
            {#each items as item}
              <button class="card" onclick={() => openExample(item)}
                use:lazyThumb={{ id: item.id, mode: thumbMode }}>
                <div class="card-thumb">
                  {#if thumbMode === 'live'}
                    {#if cardSvg[item.id]}
                      <div class="card-svg-thumb">{@html cardSvg[item.id]}</div>
                    {:else if cardLoading[item.id]}
                      <div class="card-loading"><span class="spinner">⋯</span></div>
                    {:else}
                      <img src={`/icons/${getItemIconName(item)}.svg`} alt=""
                        class="card-icon-ph" style="opacity:.2" />
                    {/if}
                  {:else}
                    <img src={getStaticThumbUrl(item, thumbMode)} alt={item.titleCN || item.title}
                      class:thumb-echarts={thumbMode === 'echarts-webp'}
                      data-thumb-fallback-index="0"
                      onload={(e) => {
                        const t = e.currentTarget as HTMLImageElement;
                        t.dataset.thumbFallbackIndex = '0';
                      }}
                      onerror={(e) => handleStaticThumbError(e, item, thumbMode)} />
                  {/if}
                </div>
                <div class="card-title">{item.titleCN || item.title}</div>
              </button>
            {/each}
          </div>
        </section>
      {/each}
    </div>
  </div>
</div>

<!-- EDITOR ──────────────────────────────────────────────────────────────── -->
<div class="page editor-page" style:display={page === 'editor' ? 'flex' : 'none'}>
  <header>
    <button class="back-btn" onclick={() => page = 'gallery'}>← Gallery</button>
    <h1>YueCharts</h1>
    <div class="backend-toggle">
      {#each ([['gc','wasm-gc'],['linear','wasm'],['echarts','echarts.js']] as [keyof typeof avail, string][]) as [val, label]}
        <label class:active={backend === val} class:unavail={loadingDone && !avail[val]}>
          <input type="radio" name="backend" value={val}
            disabled={loadingDone && !avail[val]}
            bind:group={backend}
            onchange={onRender} />
          {label}
        </label>
      {/each}
    </div>
  </header>

  <main>
    <!-- Left: editor panel -->
    <section class="panel editor-panel">
      <div class="tab-bar">
        <button class:active={tab==='json'} onclick={() => switchTab('json')}>JSON</button>
        <button class:active={tab==='js'} onclick={() => switchTab('js')}>JS</button>
        {#if tab === 'js'}
          <span class="size-inputs">
            <label>W <input type="number" bind:value={jsWidth}  min="100" max="2000" onchange={onRender} /></label>
            <label>H <input type="number" bind:value={jsHeight} min="100" max="2000" onchange={onRender} /></label>
          </span>
        {/if}
        {#if conversionError}
          <span class="conv-error">{conversionError}</span>
        {/if}
      </div>

      <!-- CodeMirror editors: always in DOM, hidden by CSS when not active -->
      <div class="cm-wrap" style:display={tab === 'json' ? 'flex' : 'none'} bind:this={jsonEditorEl}></div>
      <div class="cm-wrap" style:display={tab === 'js'   ? 'flex' : 'none'} bind:this={jsEditorEl}></div>

      <div class="toolbar">
        <button class="render-btn" onclick={onRender} disabled={rendering}>▶ Render</button>
        <button class="download-btn" onclick={onDownloadSvg} disabled={rendering || !hasSvgOutput}>Download SVG</button>
        <span class="status" class:error={statusError}>{status}</span>
      </div>
    </section>

    <!-- Right: output panel -->
    <section class="panel output-panel">
      {#if backend !== 'echarts'}
        <div class="svg-output">
          {#if svgOutput}
            {@html svgOutput}
          {:else}
            <span class="placeholder">Click ▶ Render to see the chart</span>
          {/if}
        </div>
      {/if}
      <div bind:this={echartsContainer} class="echarts-output"
        style:display={backend === 'echarts' ? 'block' : 'none'}></div>
    </section>
  </main>
</div>
