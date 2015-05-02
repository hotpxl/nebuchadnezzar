#!/usr/bin/env coffee
Q = require 'q'
_ = require 'lodash'
Progress = require 'progress'
translator = require './'
database = require '../database'

if require.main == module
  Q.all [
    database.redis.getConnection 0
    database.redis.getConnection 1
  ]
  .then (res) ->
    sourceRedis = res[0]
    targetRedis = res[1]
    Q.ninvoke sourceRedis, 'keys', '*'
    .then (keys) ->
      keys = _.filter keys, (key) ->
        key != 'progress'
      bar = new Progress('[:bar] :percent :etas',
        total: keys.length
        width: 100
      )
      translateOne = (key) ->
        Q.ninvoke sourceRedis, 'get', key
        .then (entry) ->
          entry = JSON.parse entry
          translator.baidu.translate entry.title + '\n' + entry.content.replace(/<br>/g, '')
          .then (res) ->
            d =
              translation: res
            targetRedis.set "#{entry.id}", JSON.stringify(d)
            bar.tick 1
      Q.all _.map(_.range(300), ->
        loo = ->
          val = keys.pop()
          if val
            translateOne val
            .then loo
          else
            Q()
        loo()
      )
    .then ->
      targetRedis.closeConnection()
      sourceRedis.closeConnection()
  .done()


