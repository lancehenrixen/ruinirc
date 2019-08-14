m = require \mithril
panzoom = require \panzoom
{ List } = require \../common/core

banner-uri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACoAAAALCAYAAAAJMx/IAAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4wIBCyIxZEFecgAAABl0RVh0Q29tbWVudABDcmVhdGVkIHdpdGggR0lNUFeBDhcAAABfSURBVDjLY2AYzoDj3f//A6F3SABGbD79IcTICBP7IcTICKOR1cH4uPTiC01CevGahy1KYGLocrj4xEQrIbNwiTENlagfPg7FFZ20zvkc7/7/H5IlBCM9yll8JcGwAwBpm1NJ0Jyz4AAAAABJRU5ErkJggg=="

export Layout = ->
  oncreate: -> document.add-event-listener \paste paste
  view: ->
    m \.layout,
      m \.workspaces,
        m \.workspace.workspace-left,
          m \.workspace-tabs,
            m Switch, prop: \tabsLeft, tabs: true, values: [\original, \raw]
          m \.workspace-bg,
            m Tab, prop: \tabsLeft, tab: \original, content: (m Image, type: \original)
            m Tab, prop: \tabsLeft, tab: \raw, content: m Raw
        m \.workspace.workspace-right,
          m \.workspace-tabs,
            m Switch, prop: \tabsRight, tabs: true, values: [\dithered, \resized, \effects]
          m \.workspace-bg,
            m Tab, prop: \tabsRight, tab: \dithered, content: (m Image, type: \dithered, zoom: 6)
            m Tab, prop: \tabsRight, tab: \resized, content: (m Image, type: \resized, zoom: 6)
            m Tab, prop: \tabsRight, tab: \effects, content: (m Image, type: \affected)
      m Toolbox

Toolbox = ->
  view: ->
    m \.toolbox,
      m \.control, m \img.banner src: banner-uri, draggable: false
      m \.toolbar.control,
        m \label.button \import,
          m \input.import,
            type: \file, name: \import, accept: ".bmp,.gif,.jpg,.jpeg,.jpe,.png,.tif,.tiff", onchange: ->
              if not it.target.files.length then return
              file = it.target.files[0]
              reader = new FileReader!
              reader.onload = -> app.render.send \load it.target.result
              reader.read-as-array-buffer file
        m \button (onclick: -> if prompt \paste_url_bruh then app.render.send \load that), \url
        m \button (onclick: -> navigator.clipboard.write-text app.render.stringified), \copy
        m \button { disabled: true }, \export
      m \.control-group,
        m Switch, prop: \colors, values: [\99, \16, \gray, \mono, \lrh]
        m Slider, prop: \width, min: 4, max: 240
        m Switch, prop: \resize, values: [\near, \bilin, \bicub, \herm, \bez]
        m Switch, prop: \dither, values: [\n, \a, \b, \f, \j, \o, \s, \s2, \s3, \st]
        m \.toolbar.control,
          m \button (onclick: -> app.reset-effects!), \reset_effects
        m Slider, prop: \brightness, min: -100, max: 100
        m Slider, prop: \contrast, min: -100, max: 100
        m Slider, prop: \hue, min: 0, max: 360
        m Slider, prop: \saturation, min: -100, max: 100
        m Slider, prop: \posterize, min: 0, max: 100
        m Slider, prop: \blur, min: 0, max: 100
        m Slider, prop: \red, min: -255, max: 255
        m Slider, prop: \blue, min: -255, max: 255
        m Slider, prop: \green, min: -255, max: 255
      m Status

Raw = ->
  sub = null
  oncreate: ({ dom }) ->
    sub := app.render.subscribe ->
      if it.type isnt \stringified then return
      dom.value = app.render.stringified
  onremove: -> sub.dispose!
  view: ->
    m \textarea.raw, readonly: true, wrap: \off, rows: 100

Status = ->
  oncreate: ({ dom }) ->
    app.render.subscribe ->
      if it.type isnt \status then return
      dom.inner-text = it.message
      console.log it.message
      if it.busy then dom.class-list.add \busy
      else dom.class-list.remove \busy
  view: ->
    m \.status

Image = ->
  zoom = null
  onremove: -> zoom.dispose!
  view: -> m \.image, m \canvas.image-canvas
  oncreate: ({ dom, attrs }) ->
    canvas = dom.first-element-child
    zoom := panzoom dom, { smooth-scroll: false }
    zoom.zoom-abs 0, 0, if attrs.zoom then parse-int attrs.zoom else 1
    app.render.subscribe ({ type }) ->>
      if type isnt attrs.type then return
      blob = new Blob [app.render[type]], type: \image/png
      bitmap = await create-image-bitmap blob
      canvas.width = bitmap.width
      canvas.height = bitmap.height
      canvas.style.width = bitmap.width + \px
      canvas.style.height = bitmap.height + \px
      dom.style.width = bitmap.width + \px
      dom.style.height = bitmap.height + \px
      context = canvas.get-context \2d
      context.image-smoothing-enabled = false
      context.draw-image bitmap, 0, 0
      if type is \original
        app.state.has-source = true
        app.state.source-width = bitmap.width
        app.state.source-height = bitmap.height
        m.redraw!

Slider = ->
  view: ({ attrs }) ->
    { min, max, prop, disabled } = attrs
    value = app.state[prop]
    m \label.slider.control,
      m \span.control-text prop
      m \.slider-range-container,
        m \input.slider-range,
          type: \range, min: min, max: max, value: value, disabled: disabled
          onchange: ->
            app.state[prop] = parse-float it.target.value
            app.render.update!
          onwheel: -> if document.active-element is event.target
            it.prevent-default!
            it.stop-propagation!
            if it.delta-y > 0
              app.state[prop] = Math.max app.state[prop] - 1, min
            else
              app.state[prop] = Math.min app.state[prop] + 1, max
            app.render.update!
        m \.slider-glow style: width: ((value - min) / Math.abs (max - min)) * 100 + "%"
      m \span.slider-number value

Switch = ->
  view: ({ attrs }) ->
    { prop, values, tabs } = attrs
    m \.switch, class: if tabs then \tabs else \control,
      unless tabs then m \.control-text prop
      values |> List.map ->
        id = "#{prop}-#{it}"
        m \.switch-button,
          m \input.switch-input,
            id: id, type: \radio, name: prop
            value: it, checked: it is app.state[prop]
            onchange: -> app.state[prop] = it.target.value; app.render.update!
          m \label.switch-label for: id, it

Tab = ->
  view: ({ attrs }) ->
    { prop, tab, content } = attrs
    m \.tab,
      style: display: if app.state[prop] is tab then \block else \none
      content

function paste
  it.prevent-default!
  it.stop-propagation!
  { items, files } = it.clipboard-data
  file = null
  if files.length
    file := files.0
  else if items.length
    if not /image\/.*/.test items.0.type then return
    file := items.0.get-as-file!
  if not file then return
  reader = new FileReader!
  reader.onload = -> app.render.send \load it.target.result
  reader.read-as-array-buffer file
