fs = require 'fs'
request = require 'request'
cherrio = require 'cheerio'
moment = require 'moment'
async = require 'async'
_ = require 'lodash'
redis = require('redis').createClient()
debug = require('debug') 'getCommentCount'

redis.auth 'whatever'

makeUrl = (symbol, page) ->
  "http://guba.eastmoney.com/list,#{symbol},f_#{page}.html"

getPageCount = (html) ->
  match = /',(\d+),(\d+),/.exec html('script', '.pagernums').text()
  Math.ceil(parseInt(match[1]) / parseInt(match[2]))

parseSinglePage = (symbol, page, lastEntryDate, executionDate, callback) ->
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
        [_, targetId, threadId] = threadUrl.split /[,.]/
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
        if not createDate.isValid() or Math.abs(createDate.diff(lastEntryDate, 'days')) != 0
          request "http://guba.eastmoney.com/#{threadUrl}", (error, response, body) ->
            if error or response.statusCode != 200
              throw (error ? response)
            else
              html = cherrio.load body
              [match] = /\d{4}-\d{2}-\d{2}/.exec html('.zwfbtime').text()
              createDate = moment match, 'YYYY-MM-DD'
              debug "date change from #{lastEntryDate.format 'YYYY-MM-DD'} to #{createDate.format 'YYYY-MM-DD'}"
              payload =
                threadId: threadId
                readCount: readCount
                createDate: createDate.format 'YYYY-MM-DD'
              redis.set "#{executionDate.format('YYYY-MM-DD')}:#{symbol}:#{threadId}", JSON.stringify(payload)
              callback null, createDate
        else
          payload =
            threadId: threadId
            readCount: readCount
            createDate: createDate.format 'YYYY-MM-DD'
          redis.set "#{executionDate.format('YYYY-MM-DD')}:#{symbol}:#{threadId}", JSON.stringify(payload)
          callback null, createDate
      , (err, lastEntryDate) ->
        if err
          throw err
        # Process next page
        redis.hset 'progress', symbol, page
        if page < maxPageNum
          parseSinglePage symbol, page + 1, lastEntryDate, executionDate, callback
        else
          callback()

symbolList = do ->
  JSON.parse fs.readFileSync('sse_50.json', 'ascii')

executionDate = moment()

parseSingleSymbol = (symbol, start, callback) ->
  debug "symbol #{symbol} starting from page #{start}"
  parseSinglePage symbol, start, executionDate, executionDate, callback

redis.hgetall 'progress', (err, obj) ->
  finished = 0
  if err
    throw err
  _.map symbolList, (i) ->
    start = parseInt obj?[i] ? 1
    parseSingleSymbol parseInt(i), start, ->
      if ++finished == symbolList.length
        redis.quit()

