'use strict'

const path = require('path')

const BUNDLE = process.env.BUNDLE === 'true'
const ESM = process.env.ESM === 'true'

const fileDest = `blacklight-range-limit${ESM ? '.esm' : ''}`
const external = []
const globals = {}

const rollupConfig = {
  input: path.resolve(__dirname, `app/javascript/blacklight_range_limit/index.js`),
  output: {
    file: path.resolve(__dirname, `app/assets/javascripts/blacklight_range_limit/${fileDest}.js`),
    format: ESM ? 'esm' : 'umd',
    globals,
    generatedCode: 'es2015'
  },
  external
}

if (!ESM) {
  rollupConfig.output.name = 'BlacklightRangeLimit'
}

module.exports = rollupConfig
