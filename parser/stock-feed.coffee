#!/usr/bin/env coffee
csvParse = require 'csv-parse'
fs = require 'fs'
_ = require 'lodash'
Q = require 'q'

exports.f = f = (input) ->
  Q.nfcall csvParse, input
  .then (data) ->
    filtered = _.filter data, (i) ->
      1 < i.length
    ret = {}
    _.forEach filtered, (line) ->
      ret[line[0]] =
        open: parseFloat line[1]
        close: parseFloat line[4]
        max: parseFloat line[2]
        min: parseFloat line[3]
        volume: parseFloat line[5]
        amount: parseFloat line[6]
    ret

exports.sync = sync = (inputFile, outputFile) ->
  Q.nfcall fs.readFile, inputFile, encoding: 'ascii'
  .then f
  .then (data) ->
    Q.nfcall fs.writeFile, outputFile, JSON.stringify(data), encoding: 'ascii'

if require.main == module
  do ->
    parser = new (require('argparse').ArgumentParser)(
      description: 'parse stock feed'
    )
    parser.addArgument ['--input'],
      help: 'input file'
      required: true
    parser.addArgument ['--output'],
      help: 'output file'
      required: true
    args = parser.parseArgs()
    sync args.input, args.output
    .done()
