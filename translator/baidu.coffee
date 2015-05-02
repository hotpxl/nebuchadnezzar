querystring = require 'querystring'
request = require 'request'
_ = require 'lodash'
Q = require 'q'
secret = require './baidu-secret'

translate = (q) ->
  query = querystring.stringify
    from: 'zh'
    to: 'en'
    client_id: secret.api_key
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
