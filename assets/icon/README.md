# App icon

`icon.svg` is the source: a black chaos star with a red alarm clock on
white. `icon_fg.svg` is the same artwork with a wider viewBox, so it sits in
the adaptive icon's safe zone.

Render both to 1024 px PNGs with any SVG renderer, e.g. resvg:

    resvg -w 1024 --background white icon.svg icon.png
    resvg -w 1024 icon_fg.svg icon_fg.png

then run `dart run flutter_launcher_icons` from the repository root.
