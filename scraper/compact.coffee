#!/usr/bin/env coffee
fs = require 'fs-extra'
moment = require 'moment'
debug = require('debug') 'compact'
Q = require 'q'

exports.f = f = (date, redis) ->
  Q.ninvoke redis, 'keys', '*'
  .then (res) ->
    accumulator = {}
    Q.all _.map(res, (item) ->
      if item == 'progress'
        Q()
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
          Q()
    )
    .then ->
      Q.ninvoke redis, 'save'
    .then ->
      fs.writeFileSync "#{date.format 'YYYY-MM-DD'}.json", JSON.stringify(accumulator)
      fs.copySync 'dump.rdb', "#{date.format 'YYYY-MM-DD'}.rdb"
      debug 'compact finish'
      Q.ninvoke redis, 'flushall'

