_ = require 'lodash'
assert = require('chai').assert
TokenBucket = require './token-bucket'

speedTestPeriod = 100

class RoundRobinDispatcher
  constructor: (pairs, fallback) ->
    @pairs = []
    @recent = []
    @toSchedule = 0
    assert.ok pairs?.length, 'pairs required'
    for p in pairs
      assert.ok p.action, 'field action required'
      @pairs.push
        action: p.action
        bucket: new TokenBucket(p.duration, p.threshold)
        count: 0
    assert.ok fallback, 'fallback required'
    @fallback = fallback

  get: ->
    lastScheduled = (@toSchedule - 1) %% @pairs.length
    check = =>
      @pairs[@toSchedule].bucket.get()
    incr = =>
      @toSchedule = (@toSchedule + 1) % @pairs.length
    while @toSchedule != lastScheduled and not check()
      incr()
    ret =
      if not check()
        @fallback
      else
        @recent.push @toSchedule
        @pairs[@toSchedule].count += 1
        while speedTestPeriod < @recent.length
          @pairs[@recent.shift()].count -= 1
        @pairs[@toSchedule].action
    incr()
    ret

  status: ->
    (i.count / speedTestPeriod).toFixed(2) for i in @pairs

module.exports = RoundRobinDispatcher

