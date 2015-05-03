request = require 'request'
_ = require 'lodash'
Q = require 'q'

translate = (q) ->
  query =
    from: 'zh'
    to: 'en'
    query: q
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
      res = _.pluck(data.trans_result.data, 'dst').join '\n'
      deferred.resolve res
  deferred.promise

exports.tranlate = translate

if require.main == module
  translate '招商银行怎么啦\n行怎么啦'
  .then (i) ->
    console.log i
  .done()
