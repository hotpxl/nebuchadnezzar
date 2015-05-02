#!/usr/bin/env coffee
Q = require 'q'
_ = require 'lodash'
Progress = require 'progress'
winston = require 'winston'
translator = require './'
database = require '../database'

logger = new (winston.Logger)(
  transports: [
    new (winston.transports.Console)(
      level: 'debug'
      colorize: true
      label: module.filename
    )
  ]
)

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
          src = entry.title + '\n' + entry.content.replace(/<br>/g, '')
          translator.baidu.translate src
          .then (res) ->
            d =
              translation: res
            targetRedis.set "#{entry.id}", JSON.stringify(d)
            logger.debug 'translated',
              src: src
              dst: res
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

