fs = require 'fs'
request = require 'request'
cherrio = require 'cheerio'
moment = require 'moment'
_ = require 'lodash'
redis = require('redis').createClient()
debug = require('debug') 'getCommentCount'

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
      html('.articleh').each (index, elem) ->
        parsed = cherrio(elem)
        [_, targetId, threadId] = parsed.children('.l3').children('a').attr('href').split /[,.]/
        targetId = parseInt targetId
        threadId = parseInt threadId
        readCount = parseInt parsed.children('.l1').text()
        commentCount = parseInt parsed.children('.l2').text()
        createDate = moment parsed.children('.l6').text(), 'MM-DD'
        if targetId != symbol
          # Skip global broadcasts and wrong entries
          true
        else if isNaN(threadId) or isNaN(readCount) or isNaN(commentCount) or not createDate.isValid()
          throw new Error("symbol #{symbol} page #{page} has an invalid entry: #{parsed.text()}")
          true
        else
          # Set correct year of entry
          createDate.year lastEntryDate.year()
          if createDate.isAfter lastEntryDate
            createDate.year createDate.year() - 1
          lastEntryDate = createDate
          payload =
            threadId: threadId
            readCount: readCount
            createDate: createDate.format 'YYYY-MM-DD'
          redis.set "#{executionDate.format('YYYY-MM-DD')}:#{symbol}:#{threadId}", JSON.stringify(payload)
          true
      # Process next page
      if page < getPageCount html
        parseSinglePage symbol, page + 1, lastEntryDate, executionDate, callback
      else
        callback()

symbolList = do ->
  JSON.parse fs.readFileSync('sse_50.json', 'ascii')

symbolList = symbolList[..3]

executionDate = moment()

parseSingleSymbol = (symbol, callback) ->
  parseSinglePage symbol, 1, executionDate, executionDate, callback

_.map symbolList, (i) ->
  parseSingleSymbol parseInt(i), ->
    if ++finished == symbolList.length
      redis.quit()

