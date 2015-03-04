Date::dateAdd = (size, value) ->
  value = parseInt value
  incr = 0
  switch size
    when 'day'
      incr = value * 24
      @dateAdd 'hour', incr
    when 'hour'
      incr = value * 60
      @dateAdd 'minute', incr
    when 'week'
      incr = value * 7
      @dateAdd 'day', incr
    when 'minute'
      incr = value * 60
      @dateAdd 'second', incr
    when 'second'
      incr = value * 1000
      @dateAdd 'millisecond', incr
    when 'month'
      value = value + @getUTCMonth()
      if value / 12 > 0
        @dateAdd 'year', value / 12
        value = value % 12
      @setUTCMonth value
    when 'millisecond'
      @setTime @getTime() + value
    when 'year'
      @setFullYear @getUTCFullYear() + value
    else
      throw new Error('Invalid date increment passed')
      break
  return
