/**
 * Evaluate an example option source file and print normalized JSON.
 *
 * Usage:
 *   node tools/eval-option.js examples/js/polar-line2.js
 *   node tools/eval-option.js examples/bar.json
 */

'use strict';

const path = require('path');
const { loadOptionFile, loadEchartsExampleFile } = require('./option-loader');

function isLikelyEchartsExample(filePath) {
  const normalized = path.resolve(filePath).replace(/\\/g, '/').toLowerCase();
  return normalized.includes('/examples/js/') || normalized.includes('/public/examples/js/');
}

async function main() {
  const filePath = process.argv[2];
  if (!filePath) {
    process.stderr.write('Usage: node tools/eval-option.js <option-file>\n');
    process.exit(1);
  }

  try {
    let option;
    if (isLikelyEchartsExample(filePath)) {
      const loaded = await loadEchartsExampleFile(filePath, path.resolve('examples'));
      option = loaded && loaded.maps && loaded.maps.length > 0
        ? { ...loaded.option, maps: loaded.maps }
        : loaded.option;
    } else {
      option = loadOptionFile(filePath);
    }
    process.stdout.write(JSON.stringify(option, null, 2) + '\n');
  } catch (e) {
    process.stderr.write('Error evaluating option file: ' + e.message + '\n');
    process.exit(1);
  }
}

void main();
