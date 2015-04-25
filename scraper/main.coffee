#!/usr/bin/env coffee
redis = require('redis').createClient()
moment = require 'moment'
getCommentCount = require './get-comment-count'
compact = require './compact'
Q = require 'q'

redis.auth 'whatever'
executionDate = moment()
getCommentCount.f executionDate, redis
.then ->
  compact.f executionDate, redis
.then ->
  redis.quit()
.done()

