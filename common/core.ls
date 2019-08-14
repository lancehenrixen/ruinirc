export List =
  each: (fn, xs) --> xs.for-each fn
  map: (fn, xs) --> xs.map fn
  join: (sep, xs) --> xs.join sep

export Func =
  id: (x) -> x
  debounce: (wait = 100, func) ->
    timeout = null
    args = null
    context = null
    timestamp = null
    result = null
    debounced = ->
      context := this
      args := arguments
      timestamp := Date.now!
      call-now = not timeout
      if not timeout then timeout := set-timeout later, wait
      if call-now
        result := func.apply context, args
        context := null
        args := null
      return result
    debounced.clear = ->
      if timeout
        clear-timeout timeout
        timeout := null
    debounced.flush = ->
      if timeout
        result := func.apply context, args
        context := null
        args := null
    return debounced

    function later
      last = Date.now! - timestamp

      if last < wait and last >= 0
        timeout := set-timeout later, wait - last
      else
        timeout := null
        result := func.apply context, args
        context = null
        args = null

      
