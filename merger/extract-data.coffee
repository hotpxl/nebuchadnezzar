#!/usr/bin/env coffee
_ = require 'lodash'
fs = require 'fs'
path = require 'path'
Q = require 'q'
utils = require '../utils'
parser = require '../parser'

exports.sync = sync = (startDate, endDate, location) ->
  Q.nfcall fs.readFile, location.compositeIndexFile, encoding: 'ascii'
  .then (data) ->
    compositeIndex = JSON.parse data
    Q.nfcall fs.readFile, location.bulletinDataFile, encoding: 'ascii'
    .then (data) ->
      parser.bulletin.f JSON.parse(data)
    .then (bulletinData) ->
      dateRange = utils.weekDayRange startDate, endDate
      Q.all _.map(compositeIndex, (symbol) ->
        Q.nfcall fs.readFile, path.join(location.stockFeedDir, "SH#{symbol}.txt"), encoding: 'utf-8'
        .then parser.stockFeed.f
        .then (stockFeedData) ->
          symbolBulletin = bulletinData[symbol]
          pairedData = []
          _.forEach dateRange, (date) ->
            readCount = symbolBulletin[date]?.readCount ? pairedData[pairedData.length - 1]?.readCount ? 0
            volume = stockFeedData[date]?.volume ? pairedData[pairedData.length - 1]?.volume ? 0
            close = stockFeedData[date]?.close ? pairedData[pairedData.length - 1]?.close ? 0
            pairedData.push
              date: date
              readCount: readCount
              volume: volume
              close: close
          Q.nfcall fs.writeFile, path.join(location.outputDir, "#{symbol}.json"), JSON.stringify(pairedData), encoding: 'ascii'
      )

if require.main == module
  do (parser) ->
    parser = new (require('argparse').ArgumentParser)(
      description: 'extract data'
    )
    parser.addArgument ['--start-date'],
      help: 'start date'
      required: true
      dest: 'startDate'
    parser.addArgument ['--end-date'],
      help: 'end date'
      required: true
      dest: 'endDate'
    parser.addArgument ['--composite-index'],
      help: 'composite index file'
      required: true
      dest: 'compositeIndex'
    parser.addArgument ['--bulletin-data'],
      help: 'bulletin data file'
      required: true
      dest: 'bulletinData'
    parser.addArgument ['--stock-feed'],
      help: 'stock feed directory'
      required: true
      dest: 'stockFeed'
    parser.addArgument ['--output'],
      help: 'output directory'
      required: true
    args = parser.parseArgs()
    sync args.startDate, args.endDate,
      compositeIndexFile: args.compositeIndex
      bulletinDataFile: args.bulletinData
      stockFeedDir: args.stockFeed
      outputDir: args.output
    .done()
