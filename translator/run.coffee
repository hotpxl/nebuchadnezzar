#!/usr/bin/env coffee
Q = require 'q'
translator = require './'
database = require '../database'

if require.main == module
  sourceRedis = database.redis.getConnection 0
  targetRedis = database.redis.getConnection 1
  Q.ninvoke sourceRedis, 'keys', '*'
  .then (keys) ->
    keys = _.remove keys, (key) ->
      key == 'progress'
    Q.ninvoke sourceRedis, 'get', keys[0]
    .then (entry) ->
      console.log entry

