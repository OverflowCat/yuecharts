/**
 * ECharts SSR CLI renderer.
 * 
 * Usage:
 *   node tools/echarts-render.js examples/bar.json
 *   node tools/echarts-render.js examples/js/polar-line2.js
 *   Get-Content examples/bar.json | node tools/echarts-render.js
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
