assert = require('chai').assert

class TokenBucket
  constructor: (@duration, @threshold) ->
    @duration = parseInt @duration
    @threshold = parseInt @threshold
    assert.isNumber @duration, 'duration required as int'
    assert.isFalse isNaN(@duration), 'duration required as int'
    assert.isNumber @threshold, 'threshold required as int'
    assert.isFalse isNaN(@threshold), 'threshold required as int'
    @lastTime = (new Date()).getTime()
    @currentVolume = 0

  get: ->
    currentTime = (new Date()).getTime()
    @currentVolume = Math.min @duration * @threshold, @currentVolume + currentTime - @lastTime
    @lastTime = currentTime
    if @currentVolume < @duration
      false
    else
      @currentVolume -= @duration
      true

module.exports = TokenBucket
