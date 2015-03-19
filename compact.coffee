async = require 'async'
fs = require 'fs-extra'
moment = require 'moment'
debug = require('debug') 'compact'

exports.f = f = (date, redis) ->
  redis.keys '*', (err, res) ->
    throw err if err?
    accumulator = {}
    async.eachLimit res, 128, (item, callback) ->
      if item == 'progress'
        callback()
      else
        [_, symbol, _] = item.split(':')
        symbol = parseInt symbol
        accumulator[symbol] ?= {}
        redis.get item, (err, res) ->
          throw err if err?
          payload = JSON.parse res
          readCount = payload.readCount
          commentCount = payload.commentCount
          createDate = payload.createDate
          accumulator[symbol][createDate] ?=
            readCount: 0
            commentCount: 0
          accumulator[symbol][createDate].readCount += readCount
          accumulator[symbol][createDate].commentCount += commentCount
          callback()
    , (err) ->
      throw err if err?
      redis.save()
      fs.writeFileSync "#{date.format 'YYYY-MM-DD'}.json", JSON.stringify(accumulator)
      fs.copySync 'dump.rdb', "#{date.format 'YYYY-MM-DD'}.rdb"
      redis.flushall()
      debug 'compact finish'

if require.main == module
  f moment(), require('redis').createClient()
