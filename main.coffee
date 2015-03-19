redis = require('redis').createClient()
async = require 'async'
moment = require 'moment'
get_comment_count = require './get_comment_count'
compact = require './compact'

redis.auth 'whatever'
executionDate = moment()
async.series [
  (callback) ->
    get_comment_count.f executionDate, redis, callback
  , (callback) ->
    compact.f executionDate, redis, callback
], (err, _res) ->
  throw err if err?
  redis.quit()

