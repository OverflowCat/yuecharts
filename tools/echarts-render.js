/**
 * ECharts SSR CLI renderer.
 *
 * Usage:
 *   node tools/echarts-render.js examples/bar.json
 *   node tools/echarts-render.js examples/js/polar-line2.js
 *   Get-Content examples/bar.json | node tools/echarts-render.js
 *
 * Supported input shapes:
 *   1. Plain ECharts option JSON/object (backward compatible)
 *   2. Interaction envelope:
 *      {
 *        width, height, maps,
 *        option: { ...echarts option... },
 *        interaction: {
 *          optionPatch: { ...partial echarts option... },
 *          state: {
 *            legendSelected: { "Foo": false },
 *            seriesDataSelected: [
 *              { seriesIndex: 0, dataIndex: 2, selected: true }
 *            ],
 *            geoRegionSelected: [
 *              { geoIndex: 0, name: "Beijing", selected: true }
 *            ],
 *            visualMapSelected: [
 *              { visualMapIndex: 0, key: "0", selected: false }
 *            ]
 *          },
 *          dispatchActions: [
 *            { type: 'legendToggleSelect', name: 'Foo' },
 *            { type: 'highlight', seriesIndex: 0, dataIndex: 2 }
 *          ]
 *        }
 *      }
 *
 * Reads an ECharts option file from either a file argument or stdin, renders it
 * via ECharts SSR (SVG renderer, no DOM required), and writes the SVG to
 * stdout.
 *
 * File inputs may be JSON or JS. JS files are evaluated and the resulting
 * top-level `option` value is used. Width/height default to 600x400 if not
 * specified in the option object. Stdin remains JSON-only.
 */

'use strict';

const echarts = require('E:/recharts/echarts/dist/echarts.js');
const { loadOptionFile, loadOptionText } = require('./option-loader');

function isPlainObject(value) {
  return !!value && typeof value === 'object' && !Array.isArray(value);
}

function deepMergeOption(target, patch) {
  if (!isPlainObject(target) || !isPlainObject(patch)) {
    return patch;
  }
  for (const [key, value] of Object.entries(patch)) {
    if (Array.isArray(value)) {
      target[key] = value.map(item => item);
      continue;
    }
    if (isPlainObject(value) && isPlainObject(target[key])) {
      deepMergeOption(target[key], value);
      continue;
    }
    target[key] = value;
  }
  return target;
}

function cloneOptionRoot(option) {
  if (!isPlainObject(option)) {
    return {};
  }
  return { ...option };
}

function normalizeRenderRequest(inputJson) {
  const hasEnvelopeOption = isPlainObject(inputJson) && isPlainObject(inputJson.option);
  const baseOption = hasEnvelopeOption ? cloneOptionRoot(inputJson.option) : cloneOptionRoot(inputJson);
  const interaction = isPlainObject(inputJson) && isPlainObject(inputJson.interaction)
    ? inputJson.interaction
    : null;

  const width = isPlainObject(inputJson) && inputJson.width != null
    ? inputJson.width
    : (baseOption.width || 600);
  const height = isPlainObject(inputJson) && inputJson.height != null
    ? inputJson.height
    : (baseOption.height || 400);
  const maps = isPlainObject(inputJson) && Array.isArray(inputJson.maps)
    ? inputJson.maps
    : (Array.isArray(baseOption.maps) ? baseOption.maps : []);

  delete baseOption.width;
  delete baseOption.height;
  delete baseOption.maps;
  delete baseOption.option;
  delete baseOption.interaction;

  return { width, height, maps, option: baseOption, interaction };
}

function ensureLegendSelected(option) {
  if (!isPlainObject(option.legend)) {
    option.legend = {};
  }
  if (!isPlainObject(option.legend.selected)) {
    option.legend.selected = {};
  }
  return option.legend.selected;
}

function resolveSeries(option, selector) {
  const series = Array.isArray(option.series) ? option.series : [];
  if (Number.isInteger(selector.seriesIndex)) {
    return series[selector.seriesIndex] || null;
  }
  if (typeof selector.seriesName === 'string') {
    return series.find(item => item && item.name === selector.seriesName) || null;
  }
  return null;
}

function ensureSeriesDataItem(series, selector) {
  if (!series || !Array.isArray(series.data)) {
    return null;
  }
  if (Number.isInteger(selector.dataIndex)) {
    const item = series.data[selector.dataIndex];
    if (isPlainObject(item)) {
      return item;
    }
    if (item != null) {
      const wrapped = { value: item };
      series.data[selector.dataIndex] = wrapped;
      return wrapped;
    }
    return null;
  }
  if (typeof selector.name === 'string') {
    for (let i = 0; i < series.data.length; i += 1) {
      const item = series.data[i];
      if (isPlainObject(item) && item.name === selector.name) {
        return item;
      }
    }
  }
  return null;
}

function ensureGeoRegion(option, selector) {
  const geoList = Array.isArray(option.geo) ? option.geo : (option.geo ? [option.geo] : []);
  const geoIndex = Number.isInteger(selector.geoIndex) ? selector.geoIndex : 0;
  const geo = geoList[geoIndex];
  if (!isPlainObject(geo) || typeof selector.name !== 'string') {
    return null;
  }
  if (!Array.isArray(geo.regions)) {
    geo.regions = [];
  }
  let region = geo.regions.find(item => item && item.name === selector.name) || null;
  if (!region) {
    region = { name: selector.name };
    geo.regions.push(region);
  }
  return region;
}

function ensureVisualMapSelected(option, selector) {
  const visualMaps = Array.isArray(option.visualMap)
    ? option.visualMap
    : (option.visualMap ? [option.visualMap] : []);
  const visualMapIndex = Number.isInteger(selector.visualMapIndex) ? selector.visualMapIndex : 0;
  const visualMap = visualMaps[visualMapIndex];
  if (!isPlainObject(visualMap)) {
    return null;
  }
  if (!isPlainObject(visualMap.selected)) {
    visualMap.selected = {};
  }
  return visualMap.selected;
}

function applyInteractionState(option, interaction) {
  const state = isPlainObject(interaction) && isPlainObject(interaction.state)
    ? interaction.state
    : null;
  if (!state) {
    return;
  }

  if (isPlainObject(state.legendSelected)) {
    const legendSelected = ensureLegendSelected(option);
    for (const [name, selected] of Object.entries(state.legendSelected)) {
      legendSelected[name] = !!selected;
    }
  }

  if (Array.isArray(state.seriesDataSelected)) {
    for (const item of state.seriesDataSelected) {
      if (!isPlainObject(item)) {
        continue;
      }
      const series = resolveSeries(option, item);
      const dataItem = ensureSeriesDataItem(series, item);
      if (dataItem) {
        dataItem.selected = item.selected !== false;
      }
    }
  }

  if (Array.isArray(state.geoRegionSelected)) {
    for (const item of state.geoRegionSelected) {
      if (!isPlainObject(item)) {
        continue;
      }
      const region = ensureGeoRegion(option, item);
      if (region) {
        region.selected = item.selected !== false;
      }
    }
  }

  if (Array.isArray(state.visualMapSelected)) {
    for (const item of state.visualMapSelected) {
      if (!isPlainObject(item) || item.key == null) {
        continue;
      }
      const selectedMap = ensureVisualMapSelected(option, item);
      if (selectedMap) {
        selectedMap[String(item.key)] = !!item.selected;
      }
    }
  }
}

function actionPayload(type, payload) {
  return { type, ...payload };
}

function buildActionsFromInteraction(interaction) {
  const actions = [];
  if (!isPlainObject(interaction)) {
    return actions;
  }

  const state = isPlainObject(interaction.state) ? interaction.state : null;
  if (state && isPlainObject(state.legendSelected)) {
    for (const [name, selected] of Object.entries(state.legendSelected)) {
      actions.push(actionPayload(selected ? 'legendSelect' : 'legendUnSelect', { name }));
    }
  }
  if (state && Array.isArray(state.seriesDataSelected)) {
    for (const item of state.seriesDataSelected) {
      if (!isPlainObject(item)) {
        continue;
      }
      const { selected, ...locator } = item;
      actions.push(actionPayload(selected === false ? 'unselect' : 'select', locator));
    }
  }
  if (state && Array.isArray(state.focus)) {
    for (const item of state.focus) {
      if (!isPlainObject(item)) {
        continue;
      }
      const type = item.state === 'downplay' ? 'downplay' : 'highlight';
      const { state: _state, ...locator } = item;
      actions.push(actionPayload(type, locator));
    }
  }

  if (Array.isArray(interaction.dispatchActions)) {
    for (const action of interaction.dispatchActions) {
      if (isPlainObject(action) && typeof action.type === 'string') {
        actions.push(action);
      }
    }
  }
  return actions;
}

function registerMaps(optionJson) {
  const maps = Array.isArray(optionJson.maps) ? optionJson.maps : [];
  for (const mapEntry of maps) {
    if (!mapEntry || typeof mapEntry.name !== 'string' || !mapEntry.geoJSON) {
      continue;
    }
    echarts.registerMap(mapEntry.name, mapEntry.geoJSON, mapEntry.specialAreas || undefined);
  }
}

function renderOptionToSVG(optionJson) {
  const request = normalizeRenderRequest(optionJson);
  const width = request.width;
  const height = request.height;

  registerMaps({ maps: request.maps });

  const option = request.option;
  if (request.interaction && isPlainObject(request.interaction.optionPatch)) {
    deepMergeOption(option, request.interaction.optionPatch);
  }
  applyInteractionState(option, request.interaction);

  const chart = echarts.init(null, null, {
    renderer: 'svg',
    ssr: true,
    width,
    height,
  });

  try {
    chart.setOption(option);
    const actions = buildActionsFromInteraction(request.interaction);
    for (const action of actions) {
      chart.dispatchAction(action);
    }
    return chart.renderToSVGString();
  } finally {
    chart.dispose();
  }
}

function main() {
  const args = process.argv.slice(2);

  function processOption(optionJson) {
    const svg = renderOptionToSVG(optionJson);
    process.stdout.write(svg + '\n');
  }

  if (args.length > 0) {
    try {
      processOption(loadOptionFile(args[0]));
    } catch (e) {
      process.stderr.write('Error loading option file: ' + e.message + '\n');
      process.exit(1);
    }
  } else {
    let data = '';
    process.stdin.setEncoding('utf8');
    process.stdin.on('data', chunk => { data += chunk; });
    process.stdin.on('end', () => {
      try {
        processOption(loadOptionText(data, 'json'));
      } catch (e) {
        process.stderr.write('Error parsing JSON: ' + e.message + '\n');
        process.exit(1);
      }
    });
  }
}

main();