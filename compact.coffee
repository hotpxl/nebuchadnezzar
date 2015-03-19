redis = require('redis').createClient()
async = require 'async'
fs = require 'fs-extra'
moment = require 'moment'
debug = require('debug') 'compact'

exports.f = f = (date) ->
  redis.keys '*', (err, res) ->
    throw err if err?
    done = 0
    accumulator = {}
    async.eachLimit res, 128, (item, callback) ->
      if item == 'progress'
        callback()
      [_, symbol, _] = item.split(':')
      symbol = parseInt symbol
      accumulator[symbol] ?= {}
      redis.get item, (err, res) ->
        if err
          console.log item
          throw err
        # throw err if err?
        payload = JSON.parse res
        readCount = payload.readCount
        commentCount = payload.commentCount
        createDate = payload.createDate
        accumulator[symbol][createDate] ?=
          readCount: 0
          commentCount: 0
        accumulator[symbol][createDate].readCount += readCount
        accumulator[symbol][createDate].commentCount += commentCount
        if done++ % 1000 == 0
          console.log done
        callback()
    , (err) ->
      throw err if err?
      redis.save()
      fs.writeFileSync "#{date.format 'YYYY-MM-DD'}.json", JSON.stringify(accumulator)
      fs.copySync 'dump.rdb', "#{date.format 'YYYY-MM-DD'}.rdb"
      redis.flushall()
      redis.quit()

if require.main == module
  f moment()
