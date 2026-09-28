# Save a UMG diagram to a file

Renders a UMG to a graphics file (PDF, PNG, or SVG), or writes code for
one of the export backends. The output format is taken from the file
extension: `.pdf`/`.png`/`.svg` produce graphics, `.tex`/`.tikz` produce
TikZ source, and `.dot`/`.gv` produce Graphviz DOT source. Graphics may
be produced with either the base `grid` renderer (default) or the
ggplot2 backend. Graphics dimensions are in inches.

## Usage

``` r
umg_save(
  model,
  file,
  width = 6,
  height = 4.5,
  res = 300,
  theme = umg_theme(),
  backend = c("grid", "ggplot"),
  ...
)
```

## Arguments

- model:

  An object of class `umg`.

- file:

  Output path; the extension (`.pdf`, `.png`, `.svg`, `.tex`/`.tikz`,
  `.dot`/`.gv`) selects the format.

- width, height:

  Dimensions in inches for graphics devices.

- res:

  Resolution in dpi for PNG output.

- theme:

  A `umg_theme` for graphics output (see
  [`umg_theme()`](https://hsiutingyu.github.io/umg/reference/umg_theme.md)).

- backend:

  Graphics backend for raster/vector output: `"grid"` (default) or
  `"ggplot"`.

- ...:

  Passed to
  [`plot.umg()`](https://hsiutingyu.github.io/umg/reference/plot.umg.md)
  /
  [`umg_ggplot()`](https://hsiutingyu.github.io/umg/reference/umg_ggplot.md)
  (graphics),
  [`umg_to_tikz()`](https://hsiutingyu.github.io/umg/reference/umg_to_tikz.md)
  (TikZ), or
  [`umg_to_dot()`](https://hsiutingyu.github.io/umg/reference/umg_to_dot.md)
  (DOT).

## Value

The path `file`, invisibly.

## Examples

``` r
umg_save(umg_factor("F", paste0("y", 1:4)),
         tempfile(fileext = ".pdf"))
umg_save(umg_irt("2PL"), tempfile(fileext = ".tex"))
umg_save(umg_irt("2PL"), tempfile(fileext = ".dot"))
```
