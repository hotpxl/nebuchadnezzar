#!/usr/bin/env coffee
http = require 'http'
Q = require 'q'
_ = require 'lodash'
Progress = require 'progress'
winston = require 'winston'
translator = require './'
secret = require './baidu-secret'
database = require '../database'
RoundRobinDispatcher = require '../utils/round-robin-dispatcher'

logger = new (winston.Logger)(
  transports: [
    new (winston.transports.File)(
      level: 'debug'
      timestamp: true
      filename: 'log'
      label: module.filename
    )
  ]
)

http.globalAgent.maxSockets = 10

if require.main == module
  availableTranslators =
    _.map secret.apiKeys, (key) ->
      (q) ->
        translator.baidu.translate key, q
  pairs = do ->
    for i in availableTranslators
      duration: 3600 * 1000 / 20000
      threshold: 100
      action: i
  round = new RoundRobinDispatcher(pairs, translator.baiduWeb.translate)
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
          Q.ninvoke targetRedis, 'get', entry.id
          .then (targetEntry) ->
            bar.tick 1
            if JSON.parse(targetEntry)?.translation
              return
            else
              src = entry.title + '\n' + entry.content.replace(/<br>/g, '')
              translator = round.get()
              translator src
              .then (res) ->
                d =
                  translation: res
                targetRedis.set "#{entry.id}", JSON.stringify(d)
                logger.debug 'translated',
                  src: src
                  dst: res
      Q.all _.map(_.range(100), ->
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

