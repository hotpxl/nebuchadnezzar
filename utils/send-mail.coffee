os = require 'os'
nodemailer = require 'nodemailer'
smtpTransport = require 'nodemailer-smtp-transport'
Q = require 'q'
auth = require './send-mail-auth.json'

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
    text: text
  Q.ninvoke transporter, 'sendMail', mailOptions

