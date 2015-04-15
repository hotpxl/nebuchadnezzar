#!/usr/bin/env coffee
moment = require 'moment'
assert = require('chai').assert

generateDayRange = (start, end, predicate) ->
  cur = moment start, 'YYYY-MM-DD'
  endDate = moment end, 'YYYY-MM-DD'
  assert.isTrue cur.isValid(), "#{start} is not a valid date"
  assert.isTrue endDate.isValid(), "#{end} is not a valid date"
  ret = []
  while cur.isBefore endDate
    if predicate cur
      ret.push cur.format('YYYY-MM-DD')
    cur.add 1, 'days'
  ret

exports.weekDayRange = weekDayRange = (start, end) ->
  generateDayRange start, end, (i) -> 0 < i.weekday() < 6

exports.allDayRange = allDayRange = (start, end) ->
  generateDayRange start, end, -> true

