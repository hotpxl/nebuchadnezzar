class TokenBucket
  constructor: (@duration, @threshold) ->
    @duration = parseInt @duration
    @threshold = parseInt @threshold
    if not @duration
      throw new TypeError('duration required as an int')
    if not @threshold
      throw new TypeError('threshold required as an int')
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
