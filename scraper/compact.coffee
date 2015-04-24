#!/usr/bin/env coffee
fs = require 'fs-extra'
moment = require 'moment'
debug = require('debug') 'compact'
_ = require 'lodash'
Q = require 'q'

exports.f = f = (date, redis) ->
  Q.ninvoke redis, 'keys', '*'
  .then (res) ->
    _.reduce res, (accumulator, item) ->
      accumulator.then (accumulator) ->
        if item == 'progress'
          Q accumulator
        else
          [_, symbol, _] = item.split(':')
          symbol = parseInt symbol
          accumulator[symbol] ?= {}
          Q.ninvoke redis, 'get', item
          .then (res) ->
            payload = JSON.parse res
            readCount = payload.readCount
            commentCount = payload.commentCount
            createDate = payload.createDate
            accumulator[symbol][createDate] ?=
              readCount: 0
              commentCount: 0
            accumulator[symbol][createDate].readCount += readCount
            accumulator[symbol][createDate].commentCount += commentCount
            Q accumulator
    , Q {}
    .then (accumulator) ->
      Q.ninvoke redis, 'save'
      .then ->
        fs.writeFileSync "#{date.format 'YYYY-MM-DD'}.json", JSON.stringify(accumulator)
        fs.copySync 'dump.rdb', "#{date.format 'YYYY-MM-DD'}.rdb"
        debug 'compact finish'
        Q.ninvoke redis, 'flushall'

