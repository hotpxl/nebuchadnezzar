#!/usr/bin/env coffee
fs = require 'fs-extra'
moment = require 'moment'
debug = require('debug') 'compact'
# Progress = require 'progress'
_ = require 'lodash'
Q = require 'q'

getAllKeys = (redis) ->
  deferred = Q.defer()
  redis.keys '*', (err, res) ->
    deferred.reject err if err
    deferred.resolve res
  deferred.promise

exports.f = f = (date, redis) ->
  getAllKeys redis
  .then (res) ->
    # bar = new Progress('[:bar] :percent :etas',
    #   total: res.length
    #   width: 20
    # )
    deferred = Q.defer()
    loopBody = (accumulator, i) ->
      if i == res.length
        deferred.resolve accumulator
      else
        next = (accumulator) ->
          loopBody accumulator, i + 1
        item = res[i]
        # bar.tick 1
        if item == 'progress'
          next accumulator
        else
          symbol = parseInt item.split(':')[1]
          accumulator[symbol] ?= {}
          redis.get item, (err, res) ->
            deferred.reject err if err
            payload = JSON.parse res
            readCount = payload.readCount
            commentCount = payload.commentCount
            createDate = payload.createDate
            accumulator[symbol][createDate] ?=
              readCount: 0
              commentCount: 0
            accumulator[symbol][createDate].readCount += readCount
            accumulator[symbol][createDate].commentCount += commentCount
            next accumulator
    process.nextTick ->
      loopBody {}, 0
    deferred.promise
    .then (accumulator) ->
      Q.ninvoke redis, 'save'
      .then ->
        fs.writeFileSync "#{date.format 'YYYY-MM-DD'}.json", JSON.stringify(accumulator)
        fs.copySync 'dump.rdb', "#{date.format 'YYYY-MM-DD'}.rdb"
        debug 'compact finish'
        Q.ninvoke redis, 'flushall'

