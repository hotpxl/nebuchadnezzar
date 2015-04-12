#!/usr/bin/env coffee
csvParse = require 'csv-parse'
fs = require 'fs'
_ = require 'lodash'

exports.f = f = (input, callback) ->
  csvParse input, (err, data) ->
    callback err if err
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
    callback null, ret

exports.io = io = (inputFile, outputFile) ->
  fs.readFile inputFile, encoding: 'ascii', (err, data) ->
    throw err if err
    f data, (err, data) ->
      throw err if err
      fs.writeFile outputFile, JSON.stringify(data), encoding: 'ascii', (err) ->
        throw err if err

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
    io args.input, args.output
