request = require 'request'
_ = require 'lodash'
sleep = require 'sleep'
Q = require 'q'
winston = require 'winston'

logger = new (winston.Logger)(
  transports: [
    new (winston.transports.Console)(
      level: 'debug'
      colorize: true
      timestamp: true
      label: module.filename
    )
  ]
)

translate = (q) ->
  query =
    from: 'zh'
    to: 'en'
    query: q.trim()
  deferred = Q.defer()
  loo = (retry) ->
    request
      url: 'http://fanyi.baidu.com/v2transapi'
      method: 'POST'
      form: query
    , (err, response, body) ->
      if err
        deferred.reject err
      else if response.statusCode != 200
        deferred.reject new Error("translation returned status code #{response.statusCode}")
      else
        data = JSON.parse body
        if not data.trans_result
          if 0 < retry
            logger.warn 'retry request',
              data: data
            loo retry - 1
          else
            deferred.reject new Error("translation failed with reply: #{body}")
        else
          res = _.pluck(data.trans_result.data, 'dst').join '\n'
          deferred.resolve res
  loo 5
  deferred.promise

exports.translate = translate

