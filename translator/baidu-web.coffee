request = require 'request'
_ = require 'lodash'
Q = require 'q'

translate = (q) ->
  query =
    from: 'zh'
    to: 'en'
    query: q.trim()
  deferred = Q.defer()
  request.post 'http://fanyi.baidu.com/v2transapi',
    form: query
  , (err, response, body) ->
    if err
      deferred.reject err
    else if response.statusCode != 200
      deferred.reject new Error("translation returned status code #{response.statusCode}")
    else
      data = JSON.parse body
      console.log data
      res = _.pluck(data.trans_result.data, 'dst').join '\n'
      deferred.resolve res
  deferred.promise

exports.translate = translate

if require.main == module
  translate '终于开始活跃了\n'
  .then (i) ->
    console.log i
  .done()


