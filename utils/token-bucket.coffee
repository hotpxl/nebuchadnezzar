class TokenBucket
  constructor: (@speed, @threshold) ->
    @speed = parseInt @speed
    @threshold = parseInt @threshold
    if not @speed
      throw new TypeError('speed required as an int')
    if not @threshold
      throw new TypeError('threshold required as an int')
    @lastTime = (new Date()).getTime()
    @currentVolume = 0

  get: ->
    currentTime = (new Date()).getTime()
    @currentVolume = Math.min @speed * @threshold, @currentVolume + currentTime - @lastTime
    @lastTime = currentTime
    if @currentVolume < @speed
      false
    else
      @currentVolume -= @speed
      true

module.exports = TokenBucket
