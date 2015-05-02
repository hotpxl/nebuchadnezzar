redis = require('redis')
connection = null
clientCount = 0

closeConnection = ->
  clientCount -= 1
  if clientCount == 0
    connection.quit()
    connection = null

getConnection = ->
  clientCount += 1
  if not connection
    connection = redis.createClient
      parser: 'hiredis'
      auth_pass: 'whatever'
    connection.closeConnection = closeConnection
  connection

exports.getConnection = getConnection
