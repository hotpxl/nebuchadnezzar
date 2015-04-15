#!/usr/bin/env coffee
fs = require 'fs'
_ = require 'lodash'
Q = require 'q'

exports.f = f = (data, fields) ->
  _.map data, (i) ->
    _.map fields, (field) ->
      i[field]
    .join ','
  .join '\n'

exports.sync = sync = (inputFile, outputFile, fields) ->
  Q.nfcall fs.readFile, inputFile, encoding: 'utf-8'
  .then JSON.parse
  .then (data) ->
    f data, fields
  .then (csv) ->
    Q.nfcall fs.writeFile, outputFile, csv, 'utf-8'

if require.main == module
  do ->
    parser = new (require('argparse').ArgumentParser)(
      description: 'convert json to csv file'
    )
    parser.addArgument ['--input'],
      help: 'input file'
      required: true
    parser.addArgument ['--output'],
      help: 'output file'
      required: true
    parser.addArgument ['--use'],
      help: 'field to use'
      required: true
      action: 'append'
    args = parser.parseArgs()
    sync args.input, args.output, args.use
    .done()
