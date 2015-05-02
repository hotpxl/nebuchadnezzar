redis = require 'redis'
winston = require 'winston'
Q = require 'q'
connectionPool = {}

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

closeConnection = (db) ->
  connectionPool[db].count -= 1
  if connectionPool[db].count == 0
    connectionPool[db].connection.quit()
    logger.debug "redis connection to #{db} closed"
    delete connectionPool[db]
    return

getConnection = (db) ->
  db ?= 0
  if not connectionPool[db]
    connection = redis.createClient
      parser: 'hiredis'
      auth_pass: 'whatever'
    Q.ninvoke connection, 'select', db
    .then ->
      connection.closeConnection = ->
        closeConnection db
      connectionPool[db] =
        connection: connection
        count: 1
      logger.debug "redis connection to #{db} established"
      connection
  else
    connectionPool[db].count += 1
    Q connectionPool[db].connection

exports.getConnection = getConnection
