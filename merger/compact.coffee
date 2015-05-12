#!/usr/bin/env coffee
fs = require 'fs-extra'
moment = require 'moment'
_ = require 'lodash'
Q = require 'q'
database = require '../database'
utils = require '../utils'

logger = utils.logging.newConsoleLogger module.filename

threshold = 0.5

sync = ->
  symbolList = do ->
    JSON.parse fs.readFileSync('../data/sse_50.json', 'ascii')
  symbolList = ['600036']
  database.redis.getConnection 0
  .then (keyRedis) ->
    database.redis.getConnection 2
    .then (sentimentRedis) ->
      accumulator = {}
      Q.all _.map(symbolList, (symbol) ->
        accumulator[symbol] = {}
        Q.ninvoke keyRedis, 'keys', "#{symbol}:*"
        .then (symbolKeys) ->
          deferred = Q.defer()
          loo = ->
            val = symbolKeys.pop()
            if val
              logger.info 'processing',
                key: val
              Q.ninvoke keyRedis, 'get', val
              .then (item) ->
                payload = JSON.parse item
                clickCount = payload.clickCount
                publishDate = moment(payload.publishTime).format 'YYYY-MM-DD'
                accumulator[symbol][publishDate] ?=
                  clickCount: 0
                  positiveCount: 0
                  negativeCount: 0
                accumulator[symbol][publishDate].clickCount += clickCount
                Q.ninvoke sentimentRedis, 'get', item.id
                .then (sent) ->
                  sent = parseFloat sent
                  logger.info 'sentiment',
                    sent: sent
                  if sent < threshold
                    accumulator[symbol][publishDate].negativeCount += 1
                  else
                    accumulator[symbol][publishDate].positiveCount += 1
              .then loo
              .fail deferred.reject
              .done()
            else
              deferred.resolve()
          loo()
          deferred.promise
      )
      .then ->
        today = moment()
        fs.writeFileSync "#{today.format 'YYYY-MM-DD'}.json", JSON.stringify(accumulator)
        sentimentRedis.closeConnection()
    .then ->
      keyRedis.closeConnection()

exports.sync = sync

if require.main == module
  parser = new (require('argparse').ArgumentParser)(
    description: 'compact data'
  )
  args = parser.parseArgs()
  sync()
  .done()
