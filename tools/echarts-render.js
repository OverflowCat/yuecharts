/**
 * ECharts SSR CLI renderer.
 * 
 * Usage:
 *   node tools/echarts-render.js examples/bar.json
 *   Get-Content examples/bar.json | node tools/echarts-render.js
 *
 * Reads an ECharts option JSON (with optional top-level "width" and "height"
 * fields) from either a file argument or stdin, renders it via ECharts SSR
 * (SVG renderer, no DOM required), and writes the SVG to stdout.
 *
 * The input JSON should be a valid ECharts option object. Width/height default
 * to 600x400 if not specified in the JSON.
 */

'use strict';

const echarts = require('E:/recharts/echarts/dist/echarts.js');
const fs = require('fs');
const path = require('path');

function renderOptionToSVG(optionJson) {
  const width = optionJson.width || 600;
  const height = optionJson.height || 400;

  // Clone option without yuecharts-specific top-level fields
  const option = Object.assign({}, optionJson);
  delete option.width;
  delete option.height;

  const chart = echarts.init(null, null, {
    renderer: 'svg',
    ssr: true,
    width,
    height,
  });

  try {
    chart.setOption(option);
    return chart.renderToSVGString();
  } finally {
    chart.dispose();
  }
}

function main() {
  const args = process.argv.slice(2);

  function processJson(jsonStr) {
    let optionJson;
    try {
      optionJson = JSON.parse(jsonStr);
    } catch (e) {
      process.stderr.write('Error parsing JSON: ' + e.message + '\n');
      process.exit(1);
    }
    const svg = renderOptionToSVG(optionJson);
    process.stdout.write(svg + '\n');
  }

  if (args.length > 0) {
    // File argument
    const filePath = path.resolve(args[0]);
    try {
      const jsonStr = fs.readFileSync(filePath, 'utf8');
      processJson(jsonStr);
    } catch (e) {
      process.stderr.write('Error reading file: ' + e.message + '\n');
      process.exit(1);
    }
  } else {
    // Read from stdin
    let data = '';
    process.stdin.setEncoding('utf8');
    process.stdin.on('data', chunk => { data += chunk; });
    process.stdin.on('end', () => { processJson(data); });
  }
}

main();
