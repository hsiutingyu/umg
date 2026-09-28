# Construct a UMG rendering theme

Returns a named list of visual constants controlling colours, sizes, and
line weights for
[`plot.umg()`](https://hsiutingyu.github.io/umg/reference/plot.umg.md).
The defaults reproduce the grayscale lexicon of the accompanying
article; `style = "slide"` enlarges type and thickens strokes for
projection, and `style = "journal"` is the compact grayscale default.
Any individual element may be overridden through `...`.

## Usage

``` r
umg_theme(style = c("journal", "slide", "cb"), ...)
```

## Arguments

- style:

  One of `"journal"` (default), `"slide"`, or `"cb"` (a
  colour-blind-safe palette that adds hue to the observability cue while
  keeping fill luminance informative).

- ...:

  Named overrides for any theme element, e.g.
  `observed_fill = "grey80"`, `label_cex = 0.9`.

## Value

A named list of class `umg_theme`.

## Examples

``` r
th <- umg_theme("slide", label_cex = 1.1)
```
