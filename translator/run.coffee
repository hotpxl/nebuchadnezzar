#!/usr/bin/env coffee
Q = require 'q'
_ = require 'lodash'
translator = require './'
database = require '../database'

if require.main == module
  Q.all [
    database.redis.getConnection 0
  , database.redis.getConnection 1
  ]
  .then (res) ->
    sourceRedis = res[0]
    targetRedis = res[1]
    Q.ninvoke sourceRedis, 'keys', '*'
    .then (keys) ->
      keys = _.filter keys, (key) ->
        key != 'progress'
      Q.ninvoke sourceRedis, 'get', keys[0]
      .then (entry) ->
        entry = JSON.parse entry
        translator.baidu.translate entry.title + '\n' + entry.content.replace(/<br>/g, '')
      .then (res) ->
        console.log res
    .then ->
      targetRedis.closeConnection()
      sourceRedis.closeConnection()
  .done()


