#!/usr/bin/env coffee
fs = require 'fs'
request = require 'request'
Q = require 'q'
_ = require 'lodash'
moment = require 'moment'
winston = require 'winston'

logger = new (winston.Logger)(
  transports: [
    new (winston.transports.Console)(
      level: 'debug'
      colorize: true
      label: module.filename
    )
  ]
)

requestAsync = (url) ->
  deferred = Q.defer()
  request url, (err, response, body) ->
    deferred.reject err if err
    deferred.reject new Error("#{url} returned status code #{response.statusCode}") if response.statusCode != 200
    deferred.resolve body
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
  loo startPage

parseAll = (redis) ->
  symbolList = do ->
    JSON.parse fs.readFileSync('../data/sse_50.json', 'ascii')
  Q.ninvoke redis, 'hgetall', 'progress'
  .then (progress) ->
    Q.all _map(symbolList, (i) ->
      startPage = parseInt progress?[i] ? 1
      parseSingleSymbol i, startPage, redis
    )

if require.main == module
  redis = require('redis').createClient()
  parseAll redis
  .then ->
    redis.quit()
  .done()
