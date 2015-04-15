#!/usr/bin/env coffee
moment = require 'moment'
assert = require('chai').assert

exports.weekDayRange = weekDayRange = (start, end) ->
  cur = moment start, 'YYYY-MM-DD'
  endDate = moment end, 'YYYY-MM-DD'
  assert.isTrue cur.isValid(), "#{start} is not a valid date"
  assert.isTrue endDate.isValid(), "#{end} is not a valid date"
  ret = []
  while cur.isBefore endDate
    if 0 < cur.weekday() < 6
      ret.push cur.format('YYYY-MM-DD')
    cur.add 1, 'days'
  ret

