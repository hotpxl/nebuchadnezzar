#!/usr/bin/env coffee
http = require 'http'
Q = require 'q'
_ = require 'lodash'
Progress = require 'progress'
translator = require './'
database = require '../database'
utils = require '../utils'
secret = require './baidu-secret'

RoundRobinDispatcher = utils.RoundRobinDispatcher

logger = utils.logging.newFileLogger module.filename, 'log'

http.globalAgent.maxSockets = 5
averageLoad = 5

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
            # bar.tick 1
            if JSON.parse(targetEntry)?.translation
              process.stdout.write '\rskip'
              return
            else
              src = (entry.title + '\n' + entry.content)
              .replace /<br>/g, ' '
              .replace /[^0-9a-zA-Z\u4e00-\u9fa5]/g, ' '
              .trim()
              currentTranslator = round.get()
              process.stdout.write '\r'
              process.stdout.write JSON.stringify(round.status())
              currentTranslator src
              .then (res) ->
                d =
                  translation: res
                targetRedis.set "#{entry.id}", JSON.stringify(d)
                logger.debug 'translated',
                  src: src
                  dst: res
      Q.all _.map(_.range(averageLoad * Math.min(http.globalAgent.maxSockets, 50) * (availableTranslators.length + 1)), ->
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

