yargs = require 'yargs'
  .demand ['d', 's']
  .alias 'd', 'date'
  .alias 's', 'symbol'
  .help 'h'
  .alias 'h', 'help'
  .argv
fs = require 'fs'
_ = require 'lodash'

if require.main == module
  fs.readFile "#{yargs.date}.json", encoding: 'utf-8', (err, data) ->
    throw err if err
    parsed = JSON.parse data
    symbolSpecific = parsed[yargs.s]
    if not symbolSpecific?
      throw new Error("Symbol #{yargs.s} not found")
    sorted = _.sortBy ([k, v.readCount, v.commentCount] for k, v of symbolSpecific), (i) -> i[0]
    csv = _.map(sorted, (i) -> i.join(',')).join '\n'
    fs.writeFile "#{yargs.date}_#{yargs.symbol}.csv", csv, (err) ->
      throw err if err

