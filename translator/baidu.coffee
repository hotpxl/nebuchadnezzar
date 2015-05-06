querystring = require 'querystring'
request = require 'request'
_ = require 'lodash'
Q = require 'q'

translate = (key, q) ->
  q = q.trim()
  query = querystring.stringify
    from: 'zh'
    to: 'en'
    client_id: key
    q: q
  deferred = Q.defer()
  request "http://openapi.baidu.com/public/2.0/bmt/translate?#{query}", (err, response, body) ->
    if err
      deferred.reject err
    else if response.statusCode != 200
      deferred.reject new Error("translation returned status code #{response.statusCode}")
    else
      res = _.pluck JSON.parse(body).trans_result, 'dst'
      deferred.resolve res.join('\n')
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
