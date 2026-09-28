# Plot a UMG with grid graphics

Renders the diagram using the same channel allocation as the TikZ
lexicon: fill encodes observability, shape encodes support, border and
dedicated shapes encode role, and plates are rounded rectangles.
Appearance is governed by a theme (see
[`umg_theme()`](https://hsiutingyu.github.io/umg/reference/umg_theme.md));
individual vertices may override their fill by carrying a `fill`
element.

## Usage

``` r
# S3 method for class 'umg'
plot(
  x,
  theme = umg_theme(),
  parse_labels = NULL,
  node_r = NULL,
  orientation = NULL,
  ...
)
```

## Arguments

- x:

  An object of class `umg` (layout computed automatically if absent).

- theme:

  A `umg_theme` object (default
  [`umg_theme()`](https://hsiutingyu.github.io/umg/reference/umg_theme.md)),
  or a style name (`"journal"`, `"slide"`, `"cb"`).

- parse_labels:

  Logical; parse labels as plotmath. Defaults to the theme value. TeX
  `$` delimiters are stripped for display.

- node_r:

  Vertex radius in native units; defaults to the theme value.

- orientation:

  Layer direction passed to
  [`umg_layout()`](https://hsiutingyu.github.io/umg/reference/umg_layout.md):
  `"TB"` (top to bottom, default) or `"LR"` (left to right).

- ...:

  Passed to
  [`umg_layout()`](https://hsiutingyu.github.io/umg/reference/umg_layout.md)
  when a layout is absent.

## Value

Invisibly `x` (with layout attached).
