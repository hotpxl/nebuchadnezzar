#!/usr/bin/env coffee
fs = require 'fs'
request = require 'request'
cherrio = require 'cheerio'
moment = require 'moment'
Q = require 'q'
Url = require 'url'
_ = require 'lodash'
debug = require('debug') 'getCommentCount'

makeUrl = (symbol, page) ->
  "http://guba.eastmoney.com/list,#{symbol},f_#{page}.html"

getPageCount = (html) ->
  match = /\|(\d+)\|(\d+)\|/.exec html('.pagernums').data('pager')
  Math.ceil parseInt(match[1]) / parseInt(match[2])

requestPromise = (url) ->
  deferred = Q.defer()
  request url, (err, response, body) ->
    deferred.reject err if err
    deferred.reject new Error("#{url} returned status code #{response.statusCode}") if response.statusCode != 200
    deferred.resolve body
  deferred.promise

parseSinglePage = (symbol, page, lastEntryDate, executionDate, redis) ->
  debug "processing page #{page} of symbol #{symbol}"
  url = makeUrl symbol, page
  requestPromise url
  .then (body) ->
    html = cherrio.load body
    maxPageNum = getPageCount html
    entries = []
    html('.articleh').each (index, elem) ->
      parsed = cherrio(elem)
      threadUrl = parsed.children('.l3').children('a').attr 'href'
      [_news, targetId, threadId] = threadUrl.split /[,.]/
      targetId = parseInt targetId
      threadId = parseInt threadId
      readCount = parseInt parsed.children('.l1').text()
      commentCount = parseInt parsed.children('.l2').text()
      createDate = moment parsed.children('.l6').text(), 'MM-DD'
      if targetId != symbol
        # Skip global broadcasts and wrong entries
        true
      else if isNaN(threadId) or isNaN(readCount) or isNaN(commentCount)
        throw new Error("symbol #{symbol} page #{page} has an invalid entry: #{parsed.text()}")
      else
        entries.push
          threadUrl: threadUrl
          threadId: threadId
          readCount: readCount
          commentCount: commentCount
          createDate: createDate
        true
    _.reduce entries, (lastEntryDate, entry) ->
      lastEntryDate.then (lastEntryDate) ->
        threadUrl = entry.threadUrl
        threadId = entry.threadId
        readCount = entry.readCount
        commentCount = entry.commentCount
        createDate = entry.createDate
        # Set correct year of entry
        createDate.year lastEntryDate.year()
        storePayload = (createDate) ->
          payload =
            readCount: readCount
            commentCount: commentCount
            createDate: createDate.format 'YYYY-MM-DD'
          redis.set "#{executionDate.format('YYYY-MM-DD')}:#{symbol}:#{threadId}", JSON.stringify(payload)
          Q createDate
        if createDate.isValid() and -1 <= createDate.diff(lastEntryDate, 'days') <= 0
          storePayload createDate
        else
          requestPromise Url.resolve('http://guba.eastmoney.com/', threadUrl)
          .then (body) ->
            html = cherrio.load body
            [match] = /\d{4}-\d{2}-\d{2}/.exec html('.zwfbtime').text()
            createDate = moment match, 'YYYY-MM-DD'
            debug "date jumped for #{symbol} on #{page} from #{lastEntryDate.format 'YYYY-MM-DD'} to #{createDate.format 'YYYY-MM-DD'}"
            storePayload createDate
    , Q lastEntryDate
    .then (lastEntryDate) ->
      # Process next page
      redis.hset 'progress', symbol, page
      if page < maxPageNum
        parseSinglePage symbol, page + 1, lastEntryDate, executionDate, redis
      else
        Q()

parseSingleSymbol = (symbol, start, executionDate, redis) ->
  debug "symbol #{symbol} starting from page #{start}"
  parseSinglePage symbol, start, executionDate, executionDate, redis

exports.f = f = (date, redis) ->
  symbolList = do ->
    JSON.parse fs.readFileSync('../data/sse_50.json', 'ascii')
  executionDate = date
  Q.ninvoke redis, 'hgetall', 'progress'
  .then (obj) ->
    Q.all _.map(symbolList, (i) ->
      start = parseInt obj?[i] ? 1
      parseSingleSymbol parseInt(i), start, executionDate, redis
    )
