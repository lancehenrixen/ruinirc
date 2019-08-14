export RenderClient = ->
  last-props = null
  subscribers = []
  client =
    original: null, affected: null, scaled: null, dithered: null, stringified: null
    send: (type, file) ->
      props = get-props app.state
      last-props := props
      renderer.post-message { type, file, props }
    update: ->
      props = get-props app.state
      if equal-props last-props, props then return
      renderer.post-message { type: \update, props }
      last-props := props
    subscribe: ->
      subscribers.push it
      dispose: -> subscribers.splice (subscribers.index-of it), 1
  renderer.add-event-listener \message ({ data }) ->
    client[data.type] = data.buffer
    subscribers.for-each (subscriber) -> subscriber data
  return client

function get-props state then {
  state.brightness, state.contrast,
  state.hue, state.saturation, state.posterize
  state.red, state.blue, state.green
  state.blur
  state.colors, state.width, state.resize, state.dither
  state.cutoff, state.channel, state.nick,
  state.left, state.right, state.top, state.bottom
}

function equal-props a, b then
  if not a or not b then return false
  a.brightness is b.brightness and a.contrast is b.contrast and
  a.hue is b.hue and a.saturation is b.saturation and a.posterize is b.posterize and
  a.red is b.red and a.blue is b.blue and a.green is b.green and
  a.blur is b.blur and
  a.colors is b.colors and a.width is b.width and a.resize is b.resize and a.dither is b.dither and
  a.cutoff is b.cutoff and a.channel is b.channel and a.nick is b.nick and
  a.left is b.left and a.right is b.right and a.top is b.top and a.bottom is b.bottom
