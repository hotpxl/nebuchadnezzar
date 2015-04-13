#!/usr/bin/env coffee
fs = require 'fs'
path = require 'path'
_ = require 'lodash'
Q = require 'q'

exports.f = f = (input) ->
  input

exports.sync = sync = (date, symbol, dir) ->
  Q.nfcall fs.readFile, path.join(dir, "#{date}.json"), encoding: 'ascii'
  .then (data) ->
    parsed = JSON.parse data
    Q.when parsed, f
  .then (output) ->
    symbolSpecific = output[symbol]
    if not symbolSpecific?
      throw new Error("symbol #{symbol} not found")
    sorted = _.sortBy ([k, v.readCount, v.commentCount] for k, v of symbolSpecific), (i) -> i[0]
    csv = _.map(sorted, (i) -> i.join(',')).join '\n'
    Q.nfcall fs.writeFile, path.join(dir, "#{date}_#{symbol}.csv"), csv

if require.main == module
  do ->
    ArgumentParser = require('argparse').ArgumentParser
    parser = new ArgumentParser(
      description: 'parse bulletin data'
    )
    parser.addArgument ['-date'],
      help: 'date'
      required: true
    parser.addArgument ['-symbol'],
      help: 'symbol'
      required: true
    parser.addArgument ['-path'],
      help: 'path to find files'
      defaultValue: '.'
    args = parser.parseArgs()
    sync args.date, args.symbol, args.path
    .done()

