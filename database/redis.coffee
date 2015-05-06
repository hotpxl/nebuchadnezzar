redis = require 'redis'
Q = require 'q'
utils = require '../utils'
connectionPool = {}

logger = utils.logging.newConsoleLogger module.filename

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
