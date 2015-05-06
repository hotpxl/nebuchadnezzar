_ = require 'lodash'
assert = require('chai').assert
TokenBucket = require './token-bucket'

class RoundRobinDispatcher
  constructor: (pairs, fallback) ->
    @pairs = []
    @counter = []
    @toSchedule = 0
    assert.ok pairs?.length, 'pairs required'
    for p in pairs
      assert.ok p.action, 'field action required'
      @pairs.push
        action: p.action
        bucket: new TokenBucket(p.duration, p.threshold)
      @counter.push 0
    assert.ok fallback, 'fallback required'
    @fallback = fallback
    @counter.push 0

  get: ->
    lastScheduled = (@toSchedule - 1) %% @pairs.length
    check = (toSchedule) =>
      @pairs[toSchedule].bucket.get()
    incr = =>
      @toSchedule = (@toSchedule + 1) % @pairs.length
    while @toSchedule != lastScheduled and not check(@toSchedule)
      incr()
    if @toSchedule == lastScheduled and not check(@toSchedule)
      @counter[@counter.length - 1] += 1
      incr()
      @fallback
    else
      @counter[@toSchedule] += 1
      incr()
      @pairs[@toSchedule].action

  status: ->
    s = _.sum @counter
    process.stdout.write ((i / s).toFixed(2) for i in @counter).join ' '

module.exports = RoundRobinDispatcher


