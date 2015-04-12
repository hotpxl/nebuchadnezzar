#!/usr/bin/env coffee
fs = require 'fs'
_ = require 'lodash'

exports.f = f = (input, callback) ->
  callback null, input

exports.sync = sync = (date, symbol) ->
  fs.readFile "#{date}.json", encoding: 'ascii', (err, data) ->
    throw err if err
    parsed = JSON.parse data
    f parsed, (err, output) ->
      throw err if err
      symbolSpecific = output[symbol]
      if not symbolSpecific?
        throw new Error("symbol #{symbol} not found")
      sorted = _.sortBy ([k, v.readCount, v.commentCount] for k, v of symbolSpecific), (i) -> i[0]
      csv = _.map(sorted, (i) -> i.join(',')).join '\n'
      fs.writeFile "#{date}_#{symbol}.csv", csv, (err) ->
        throw err if err

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
    args = parser.parseArgs()
    sync args.date, args.symbol

