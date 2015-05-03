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

loggerFile = new (winston.Logger)(
  transports: [
    new (winston.transports.File)(
      level: 'debug'
      timestamp: true
      filename: 'baidu-web.log'
      label: module.filename
    )
  ]
)

translate = (q) ->
  q = q.trim()
  query =
    from: 'zh'
    to: 'en'
    query: q
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
          if data?.error == 3
            loggerFile.warn 'parse error skipped',
              data: data
              query: JSON.stringify q
            deferred.resolve ''
          else if 0 < retry
            logger.warn 'retry request',
              data: data
              query: JSON.stringify q
            sleep.sleep 1
            loo retry - 1
          else
            deferred.reject new Error("translation failed with reply: #{body}")
        else
          res = _.pluck(data.trans_result.data, 'dst').join '\n'
          deferred.resolve res
  loo 5
  deferred.promise

exports.translate = translate

if require.main == module
  translate '一群乌合之众 又出来乱叫了！~~~\n一跌 就看空 叫空··哈哈··· 一涨 就一片 叫好！'
  .then (i) ->
    console.log i
  .done()
