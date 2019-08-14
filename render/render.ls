Jimp = require \jimp
Dither = require \image-dither
{ Color } = require \./color
{ Irc } = require \./irc

source = null
last-props = null
jobs = []
doing-jobs = null
cropped = null
affected = null
resized = null
dithered = null
stringified = null

doing-jobs := set-timeout ->
  add-event-listener \message ({ data }) -> add-job data
  send-status \ready
  do-jobs!

do-jobs = ->>
  doing-jobs := null
  try
    while jobs.length
      job = { ...jobs.shift!, old: last-props }
      await run-job job
  catch e
    console.warn \bailing
    jobs.length = 0
    console.error e
  doing-jobs := set-timeout do-jobs, 100

run-job = ({ type, props, old, file }) ->> 
  switch type
  | \load =>
    jobs.length = 0
    last-props := null
    send-status \reading true
    source := await Jimp.read file
    send-image \original, source
    if jobs.length then return
    jobs.push { type: \update, props }
  | \update =>
    if source is null then return
    jobs.length = 0
    jobs.push { type: \crop, props, old }
    jobs.push { type: \affect, props, old }
    jobs.push { type: \resize, props, old }
    jobs.push { type: \dither, props, old }
    jobs.push { type: \stringify, props, old }
    jobs.push { type: \finish_update, props }
  | \finish_update =>
    send-status \finished
    last-props := props
  | \crop =>
    if avoid-crop props, old then return
    send-status \cropping true
    cropped := source.clone!
    # cropped.crop props.left, props.top, source.bitmap.width - props.left - props.right, source.bitmap.height - props.top - props.bottom
  | \affect =>
    if avoid-affect props, old then return
    affected := cropped.clone!
    jobs.unshift { type: \finish_affect, props }
    jobs.unshift { type: \blur, props }
    jobs.unshift { type: \posterize, props }
    jobs.unshift { type: \recolor, props }
    jobs.unshift { type: \contrast, props }
    jobs.unshift { type: \brightness, props }
  | \finish_affect
    send-image \affected affected
  | \brightness =>
    if props.brightness
      send-status \applying_brightness true
      affected.brightness (props.brightness / 100)
  | \contrast =>
    if props.contrast
      send-status \applying_contrast true
      affected.contrast (props.contrast / 100)
  | \recolor =>
    changes = []
    if props.hue then changes.push apply: \spin, params: [props.hue]
    if props.saturation > 0 then changes.push apply: \saturate, params: [props.saturation]
    if props.saturation < 0 then changes.push apply: \desaturate, params: [-props.saturation]
    if props.red then changes.push apply: \red, params: [props.red]
    if props.green then changes.push apply: \green, params: [props.green]
    if props.blue then changes.push apply: \blue, params: [props.blue]
    if not changes.length then return
    send-status \recoloring true
    affected.color changes
  | \posterize =>
    if not props.posterize then return
    send-status \posterizing true
    affected.posterize props.posterize / 100
  | \blur =>
    if not props.blur then return
    send-status \blurring true
    affected.blur props.blur
  | \resize =>
    if avoid-resize props, old then return
    send-status \resizing true
    resized := affected.clone!
    resized.resize props.width, Jimp.AUTO, resizing-method props.resize
    send-image \resized resized
  | \dither =>
    if avoid-dither props, old then return
    send-status \dithering true
    dithered := resized.clone!
    dither = new Dither matrix: dither-matrix props.dither
    dithered.bitmap.data = dither.dither dithered.bitmap.data, dithered.bitmap.width,
      find-color: Color.find props.colors
    send-image \dithered dithered
  | \stringify =>
    if avoid-stringify props, old then return
    send-status \stringifying true
    stringified := Irc.stringify props, dithered
    send-raw \stringified stringified
  | otherwise => console.warn "unrecognized job:#{that}"

add-job = -> jobs.unshift it

send-image = (type, image) ->
  (image.clone!get-buffer-async \image/png).then (buffer) -> post-message { type, buffer }

send-raw = (type, buffer) -> post-message { type, buffer }

send-status = (message, busy) -> post-message { type: \status, message, busy }

resizing-method = -> switch it
  | \near   => Jimp.RESIZE_NEAREST_NEIGHBOR
  | \bilin  => Jimp.RESIZE_BILINEAR
  | \bicub  => Jimp.RESIZE_BICUBIC
  | \herm   => Jimp.RESIZE_HERMITE
  | \bez    => Jimp.RESIZE_BEZIER

dither-matrix = -> switch it
  | \n  => Dither.matrices.none
  | \a  => Dither.matrices.atkinson
  | \b  => Dither.matrices.burkes
  | \f  => Dither.matrices.floyd-steinberg
  | \j  => Dither.matrices.jarvis-judice-ninke
  | \o  => Dither.matrices.one-dimensional
  | \s  => Dither.matrices.sierra-lite
  | \s2 => Dither.matrices.sierra2
  | \s3 => Dither.matrices.sierra3
  | \st => Dither.matrices.stucki

avoid-crop = (p, o) ->
  o isnt null
  and p.left is o.left and p.right is o.right
  and p.top is o.top and p.bottom is o.bottom

avoid-affect = (p, o) ->
  if not avoid-crop p, o then return false
  o isnt null
  and p.brightness is o.brightness and p.contrast is o.contrast
  and p.hue is o.hue and p.saturation is o.saturation
  and p.posterize is o.posterize and p.blur is o.blur
  and p.red is o.red and p.green is o.green and p.blue is o.blue

avoid-resize = (p, o) ->
  if not avoid-affect p, o then return false
  o isnt null and p.width is o.width and p.resize is o.resize

avoid-dither = (p, o) ->
  if not avoid-resize p, o then return false
  o isnt null
  and p.dither is o.dither and p.colors is o.colors

avoid-stringify = (p, o) -> avoid-dither p, o
