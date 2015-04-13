#!/usr/bin/env coffee
_ = require 'lodash'
async = require 'async'
index = require '../data/sse_50.json'
parser = require '../parser'
fs = require 'fs'
moment = require 'moment'

weekDayRange = (start, end) ->
  cur = moment start, 'YYYY-MM-DD'
  endDate = moment end, 'YYYY-MM-DD'
  ret = []
  while cur.isBefore endDate
    if 0 < cur.weekday() < 6
      ret.push cur.format('YYYY-MM-DD')
    cur.add 1, 'd'
  ret

dateRange = weekDayRange '2012-05-01', '2015-04-01'

fs.readFile 'data/2015-04-07.json', encoding: 'ascii', (err, data) ->
  throw err if err
  data = JSON.parse data
  parser.bulletin.f data, (err, bulletinData) ->
    throw err if err
    async.each index, (index, callback) ->
      fs.readFile "data/SH#{index}.txt", encoding: 'utf-8', (err, data) ->
        throw err if err
        parser.stockFeed.f data, (err, stockFeedData) ->
          throw err if err
          symbolBulletin = bulletinData[index]
          console.log index
          pairedData = []
          _.forEach dateRange, (date) ->
            readCount =
              if date of symbolBulletin
                symbolBulletin[date].readCount
              else if 0 < pairedData.length
                pairedData[pairedData.length - 1].readCount
              else 0
            amount =
              if date of stockFeedData
                stockFeedData[date].amount
              else if 0 < pairedData.length
                pairedData[pairedData.length - 1].amount
              else
                0
            pairedData.push
              date: date
              readCount: readCount
              amount: amount
          csv = _.map pairedData, (line) ->
            "#{line.readCount},#{line.amount}"
          .join '\n'
          fs.writeFile "data/#{index}.csv", csv, encoding: 'ascii', (err) ->
            throw err if err
            callback()
