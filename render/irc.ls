{ Color } = require \./color

export Irc = {}

FULL = "█"
HALF = "▀"
COLOR = ""

Irc.stringify = ({ colors }, image) ->
  { width, height } = image.bitmap
  image-color = get-image-color image, colors
  lines = []
  y = 0; while y < height
    line = ""
    x = 0; while x < width
      top = image-color x, y
      last-top = null
      bottom = \1
      last-bottom = \1
      if y < height - 1
        bottom := image-color x, y + 1
        if x > 0
          last-bottom := image-color x - 1, y + 1
      if x > 0
        last-top := image-color x - 1, y
      repeat-color = top is last-top and bottom is last-bottom
      solid-color = top is bottom
      colored =
        if repeat-color
          if solid-color then FULL
          else HALF
        else
          if solid-color
            COLOR + top + FULL
          else
            COLOR + top + \, + bottom + HALF
      line := line + colored
      x := x + 1
    lines.push line
    y := y + 2
  lines.join "\r\n"

get-image-color = (image, colors) -> (x, y) ->
  { data } = image.bitmap
  index = image.get-pixel-index x, y
  { name } = Color.nearest colors, r: data[index], g: data[index + 1], b: data[index + 2]
  name
