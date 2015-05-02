redis = require 'redis'
winston = require 'winston'
connection = null
clientCount = 0

logger = new (winston.Logger)(
  transports: [
    new (winston.transports.Console)(
      level: 'debug'
      colorize: true
      label: module.filename
    )
  ]
)

closeConnection = ->
  clientCount -= 1
  if clientCount == 0
    connection.quit()
    logger.debug 'redis connection closed'
    connection = null
    return

getConnection = ->
  clientCount += 1
  if not connection
    connection = redis.createClient
      parser: 'hiredis'
      auth_pass: 'whatever'
    connection.closeConnection = closeConnection
    logger.debug 'redis connection established'
  connection

exports.getConnection = getConnection
