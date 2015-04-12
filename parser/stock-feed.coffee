#!/usr/bin/env coffee
csvParse = require 'csv-parse'
fs = require 'fs'
_ = require 'lodash'

exports.f = f = (input, output) ->
  parser = csvParse (err, data) ->
    throw err if err
    filtered = _.filter data, (i) ->
      1 < i.length
    fs.writeFile output, JSON.stringify(filtered), encoding: 'ascii', (err) ->
      throw err if err
  fs.createReadStream(input, encodind: 'ascii').pipe parser

if require.main == module
  do ->
    ArgumentParser = require('argparse').ArgumentParser
    parser = new ArgumentParser(
      description: 'parse stock feed'
    )
    parser.addArgument ['-input'],
      help: 'input file'
      required: true
    parser.addArgument ['-output'],
      help: 'output file'
      required: true
    args = parser.parseArgs()
    f args.input, args.output
