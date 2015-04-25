#!/usr/bin/env coffee
os = require 'os'
nodemailer = require 'nodemailer'
smtpTransport = require 'nodemailer-smtp-transport'
Q = require 'q'
auth = require './send-mail-auth'

transporter = nodemailer.createTransport smtpTransport
  port: 465
  host: 'smtp.exmail.qq.com'
  secure: true
  auth: auth

exports.f = f = (to, text) ->
  mailOptions =
    from: 'no-reply@yutian.li'
    to: to
    subject: "[#{os.hostname()}] #{os.type()}-#{os.release()}-#{os.arch()} notification"
    text: "# debug info\n#{JSON.stringify os.networkInterfaces(), null, 2}\n\n# text\n#{text}"
  Q.ninvoke transporter, 'sendMail', mailOptions

if require.main == module
  do ->
    parser = new (require('argparse').ArgumentParser)(
      description: 'send mail'
    )
    parser.addArgument ['--to'],
      help: 'to address'
      required: true
    parser.addArgument ['--text'],
      help: 'text to send'
      required: true
    args = parser.parseArgs()
    f args.to, args.text
    .done()

