#!/usr/bin/env coffee
redis = require('redis').createClient()
moment = require 'moment'
get_comment_count = require './get_comment_count'
compact = require './compact'
Q = require 'q'

redis.auth 'whatever'
executionDate = moment()
get_comment_count.f executionDate, redis
.then ->
  compact.f executionDate, redis
.then ->
  redis.quit()
.done()

