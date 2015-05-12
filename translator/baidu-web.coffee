request = require 'request'
_ = require 'lodash'
sleep = require 'sleep'
Q = require 'q'
utils = require '../utils'

logger = utils.logging.newConsoleLogger module.filename

loggerFile = utils.logging.newFileLogger module.filename, 'baidu-web.log'

translate = (q) ->
  query =
    from: 'zh'
    to: 'en'
    query: q
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
    handle = request
      url: 'http://fanyi.baidu.com/v2transapi'
      method: 'POST'
      form: query
    , (err, response, body) ->
      if err
        maybeRetry err,
          err: err
          query: q
      else if response.statusCode != 200
        maybeRetry new Error("translation returned status code #{response.statusCode}"),
          statusCode: response?.statusCode
          query: q
      else
        data = JSON.parse body
        if not data.trans_result
          if data?.error == 3 or data?.error == 8
            loggerFile.warn 'error skipped',
              data: data
              query: q
            deferred.resolve ''
          else
            maybeRetry new Error("translation failed with reply: #{body}"),
              body: body
              query: q
        else
          res = _.pluck(data.trans_result.data, 'dst').join '\n'
          deferred.resolve res
    handle.on 'error', (error) ->
      maybeRetry error
  loo 5
  deferred.promise

exports.translate = translate

if require.main == module
  a = '福音\n日本发生了一件千真万确的事：有人为了装修家里，拆开了墙；日式住宅的墙壁通常是中间架了木板后，两边批上泥土，其实里面是空的。他拆墙壁的时候，发现一只壁虎被困\u2586'
  translate a.replace(/\u001d|\u2586/g, ' ')
  .then (i) ->
    console.log i
  .done()
