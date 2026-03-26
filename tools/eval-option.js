/**
 * Evaluate an example option source file and print normalized JSON.
 *
 * Usage:
 *   node tools/eval-option.js examples/js/polar-line2.js
 *   node tools/eval-option.js examples/bar.json
 */

'use strict';

const { loadOptionFile } = require('./option-loader');

function main() {
  const filePath = process.argv[2];
  if (!filePath) {
    process.stderr.write('Usage: node tools/eval-option.js <option-file>\n');
    process.exit(1);
  }

  try {
    const option = loadOptionFile(filePath);
    process.stdout.write(JSON.stringify(option, null, 2) + '\n');
  } catch (e) {
    process.stderr.write('Error evaluating option file: ' + e.message + '\n');
    process.exit(1);
  }
}

main();
