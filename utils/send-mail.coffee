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
    text: "#{text}\ndebug info:\n#{JSON.stringify os.networkInterfaces()}"
  Q.ninvoke transporter, 'sendMail', mailOptions

