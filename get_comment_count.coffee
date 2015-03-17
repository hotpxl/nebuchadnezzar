request = require 'request'
cherrio = require 'cheerio'

makeUrl = (symbol, page) ->
  "http://guba.eastmoney.com/list,#{symbol},f_#{page}.html"

getPageCount = (symbol, callback) ->
  beginning = makeUrl symbol, 1
  request beginning, (error, response, body) ->
    if not error and response.statusCode == 200
      html = cherrio.load body
      match = /',(\d+),(\d+),1/.exec html('script', '.pagernums').text()
      callback Math.ceil(parseInt(match[1]) / parseInt(match[2]))
    else
      throw (error ? response)

getPageCount 600029, (i) ->
  console.log i

# request 'http://www.sse.com.cn/market/sseindex/indexlist/s/i000010/const_list.shtml', (err, response, body) ->
#   if not err and response.statusCode == 200
#     ret = []
#     html = cherrio.load body
#     for i in html('.table3')
#       ret.push /\d{6}/.exec(i.children[0]?.children[0].data)?[0]
#     ret = ret.filter (i) -> i?
#     console.log JSON.stringify(ret)
#   else
#     console.log err
