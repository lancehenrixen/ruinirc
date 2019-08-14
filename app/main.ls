if module.hot then module.hot.dispose -> location.reload!
m = require \mithril
{ Layout } = require \./layout
{ RenderClient } = require \./renderClient

window.renderer = new Worker \../render/render.ls
window.app = App!
m.mount document.body, Layout

function App
  render: RenderClient!
  state:
    # basics
    colors: \lrh, width: 60, resize: \bicub, dither: \n
    # effects
    brightness: 0, contrast: 0, hue: 0, saturation: 0, posterize: 0, blur: 0
    red: 0, blue: 0, green: 0
    # source
    left: 0, right: 0, top: 0, bottom: 0
    # ui
    tabs-left: \original
    tabs-right: \dithered
    # image
    has-source: false
  reset-effects: ->
    Object.assign app.state,
      brightness: 0, contrast: 0, hue: 0, saturation: 0, posterize: 0, blur: 0
      red: 0, blue: 0, green: 0
    app.render.update!
