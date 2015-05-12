querystring = require 'querystring'
request = require 'request'
_ = require 'lodash'
Q = require 'q'
sleep = require 'sleep'
utils = require '../utils'

logger = utils.logging.newConsoleLogger module.filename

translate = (key, q) ->
  query = querystring.stringify
    from: 'zh'
    to: 'en'
    client_id: key
    q: q
  deferred = Q.defer()
  loo = (retry) ->
    maybeRetry = (rejection, status) ->
      status ?= rejection
      if 0 < retry
        logger.warn 'retry request', status
        sleep.sleep 1
        loo retry - 1
      else
        deferred.reject rejection
    handle = request "http://openapi.baidu.com/public/2.0/bmt/translate?#{query}", (err, response, body) ->
      if err
        maybeRetry err,
          err: err
          query: q
      else if response.statusCode != 200
        maybeRetry new Error("translation returned status code #{response.statusCode}"),
          statusCode: response?.statusCode
          query: q
      else
        res = _.pluck JSON.parse(body).trans_result, 'dst'
        deferred.resolve res.join('\n')
    handle.on 'error', (error) ->
      maybeRetry error
  loo 5
  deferred.promise

exports.translate = translate

if require.main == module
  secret = require './baidu-secret'
  Q.all _.map(secret.apiKeys, (key) ->
    translate key, '一群乌合之众 又出来乱叫了！~~~\n一跌 就看空 叫空··哈哈··· 一涨 就一片 叫好！'
    .then (i) ->
      console.log i
  )
  .done()
