#!/usr/bin/env coffee
fs = require 'fs'
_ = require 'lodash'

exports.f = f = (date, symbol) ->
  fs.readFile "#{date}.json", encoding: 'ascii', (err, data) ->
    throw err if err
    parsed = JSON.parse data
    symbolSpecific = parsed[symbol]
    if not symbolSpecific?
      throw new Error("Symbol #{symbol} not found")
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
    parser.parseArgs()
    f parser.date, parser.symbol

