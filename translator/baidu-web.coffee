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
  # preprocessing
  q = q.trim().replace /\u001d|\u2586/g, ' '
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
          if data?.error == 3 or data?.error == 8
            loggerFile.warn 'error skipped',
              data: data
              query: q
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
  a = '福音\n日本发生了一件千真万确的事：有人为了装修家里，拆开了墙；日式住宅的墙壁通常是中间架了木板后，两边批上泥土，其实里面是空的。他拆墙壁的时候，发现一只壁虎被困\u2586'
  translate a.replace(/\u001d|\u2586/g, ' ')
  .then (i) ->
    console.log i
  .done()
