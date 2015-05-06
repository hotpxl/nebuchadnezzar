winston = require 'winston'

newConsoleLogger = (label) ->
  new (winston.Logger)(
    transports: [
      new (winston.transports.Console)(
        level: 'debug'
        colorize: true
        timestamp: true
        prettyPrint: true
        label: label
      )
    ]
  )

newFileLogger = (label, filename) ->
  new (winston.Logger)(
    transports: [
      new (winston.transports.File)(
        level: 'debug'
        timestamp: true
        filename: filename
        label: label
      )
    ]
  )

exports.newConsoleLogger = newConsoleLogger
exports.newFileLogger = newFileLogger

