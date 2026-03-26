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

function loadOptionFile(filePath) {
  const resolved = path.resolve(filePath);
  const text = stripBom(fs.readFileSync(resolved, 'utf8'));
  const ext = path.extname(resolved).toLowerCase();
  if (ext === '.json') {
    return JSON.parse(text);
  }
  if (ext === '.js' || ext === '.cjs' || ext === '.mjs') {
    return evaluateOptionScript(text, resolved);
  }
  throw new Error(`Unsupported option file extension: ${ext || '(none)'}`);
}

function loadOptionText(inputText, inputKind) {
  const text = stripBom(inputText);
  if (inputKind === 'json') {
    return JSON.parse(text);
  }
  if (inputKind === 'js') {
    return evaluateOptionScript(text, path.resolve('stdin-option.js'));
  }
  throw new Error(`Unsupported option input kind: ${inputKind}`);
}

module.exports = {
  evaluateOptionScript,
  loadOptionFile,
  loadOptionText,
};
