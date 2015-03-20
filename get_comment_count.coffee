fs = require 'fs'
request = require 'request'
cherrio = require 'cheerio'
moment = require 'moment'
async = require 'async'
_ = require 'lodash'
debug = require('debug') 'getCommentCount'

makeUrl = (symbol, page) ->
  "http://guba.eastmoney.com/list,#{symbol},f_#{page}.html"

getPageCount = (html) ->
  match = /',(\d+),(\d+),/.exec html('script', '.pagernums').text()
  Math.ceil(parseInt(match[1]) / parseInt(match[2]))

parseSinglePage = (symbol, page, lastEntryDate, executionDate, redis, callback) ->
  debug "processing page #{page} of symbol #{symbol}"
  url = makeUrl symbol, page
  request url, (error, response, body) ->
    if error or response.statusCode != 200
      throw (error ? response)
    else
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
      async.reduce entries, lastEntryDate, (lastEntryDate, entry, callback) ->
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
          callback null, createDate
        if createDate.isValid() and -1 <= createDate.diff(lastEntryDate, 'days') <= 0
          storePayload createDate
        else
          request "http://guba.eastmoney.com/#{threadUrl}", (error, response, body) ->
            if error or response.statusCode != 200
              throw (error ? response)
            else
              html = cherrio.load body
              [match] = /\d{4}-\d{2}-\d{2}/.exec html('.zwfbtime').text()
              createDate = moment match, 'YYYY-MM-DD'
              debug "date change from #{lastEntryDate.format 'YYYY-MM-DD'} to #{createDate.format 'YYYY-MM-DD'}"
              storePayload createDate
      , (err, lastEntryDate) ->
        throw err if err?
        # Process next page
        redis.hset 'progress', symbol, page
        if page < maxPageNum
          parseSinglePage symbol, page + 1, lastEntryDate, executionDate, redis, callback
        else
          callback()

parseSingleSymbol = (symbol, start, executionDate, redis, callback) ->
  debug "symbol #{symbol} starting from page #{start}"
  parseSinglePage symbol, start, executionDate, executionDate, redis, callback

exports.f = f = (date, redis, callback) ->
  symbolList = do ->
    JSON.parse fs.readFileSync('sse_50.json', 'ascii')
  executionDate = date
  redis.hgetall 'progress', (err, obj) ->
    throw err if err?
    finished = 0
    _.map symbolList, (i) ->
      start = parseInt obj?[i] ? 1
      parseSingleSymbol parseInt(i), start, executionDate, redis, ->
        if ++finished == symbolList.length
          callback()
