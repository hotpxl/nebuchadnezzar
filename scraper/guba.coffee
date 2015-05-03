#!/usr/bin/env coffee
fs = require 'fs'
http = require 'http'
request = require 'request'
Q = require 'q'
_ = require 'lodash'
moment = require 'moment'
winston = require 'winston'
database = require '../database'

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

http.globalAgent.maxSockets = Infinity

requestAsync = (url) ->
  deferred = Q.defer()
  loo = (retry) ->
    request
      uri: url
      timeout: 5000
    , (err, response, body) ->
      maybeRetry = (rejection) ->
        if 0 < retry
          logger.warn 'retry request',
            url: url
            err: err
            response: response
          loo retry - 1
        else
          deferred.reject rejection
      if err
        maybeRetry err
      else if response.statusCode != 200
        maybeRetry new Error("#{url} returned status code #{response.statusCode}")
      else
        deferred.resolve body
  loo 5
  deferred.promise

makeUrl = (symbol, page) ->
  "http://m.guba.eastmoney.com/getdata/articlelist?code=#{symbol}&count=200&thispage=#{page}"

stripSingleEntry = (symbol, entry) ->
  symbol: symbol
  id: entry.post_id
  title: entry.post_title
  content: entry.post_content
  publishTime: moment(entry.post_publish_time).toISOString()
  lastReplyTime: moment(entry.post_last_time).toISOString()
  clickCount: entry.post_click_count
  commentCount: entry.post_comment_count

dumpEntries = (entries, redis) ->
  _.map entries, (entry) ->
    redis.set "#{entry.symbol}:#{entry.id}", JSON.stringify(entry)

parseSinglePage = (symbol, page, redis) ->
  url = makeUrl symbol, page
  requestAsync url
  .then (data) ->
    data = JSON.parse data
    entries = _.map data.re, (post) ->
      stripSingleEntry symbol, post
    dumpEntries entries, redis
    redis.hset 'progress', symbol, page
    logger.debug 'processed',
      length: entries.length
      symbol: symbol
      page: page
    entries.length

parseSingleSymbol = (symbol, startPage, redis) ->
  logger.debug 'starting',
    symbol: symbol
    startPage: startPage
  loo = (page) ->
    parseSinglePage symbol, page, redis
    .then (res) ->
      if res == 0
        return
      else
        loo page + 1
    # unroll = 4
    # Q.all _.map([page..page + unroll - 1], (page) ->
    #   parseSinglePage symbol, page, redis
    # )
    # .then (res) ->
    #   if _.min(res) == 0
    #     return
    #   else
    #     loo page + unroll
  loo startPage

parseAll = (redis) ->
  symbolList = do ->
    JSON.parse fs.readFileSync('../data/sse_50.json', 'ascii')
  Q.ninvoke redis, 'hgetall', 'progress'
  .then (progress) ->
    Q.all _.map(symbolList, (i) ->
      startPage = parseInt progress?[i] ? 1
      parseSingleSymbol i, startPage, redis
    )

if require.main == module
  database.redis.getConnection(0)
  .then (redis) ->
    parseAll redis
  .then ->
    redis.closeConnection()
  .done()
