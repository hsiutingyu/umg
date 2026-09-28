# Coerce a UMG to a data frame

Returns the vertices or the edges of a diagram as a tidy data frame,
which is convenient for inspection, tabulation in a manuscript, and
programmatic edits before re-assembling with
[`umg_model()`](https://hsiutingyu.github.io/umg/reference/umg_model.md).

## Usage

``` r
# S3 method for class 'umg'
as.data.frame(
  x,
  row.names = NULL,
  optional = FALSE,
  what = c("edges", "vertices"),
  ...
)
```

## Arguments

- x:

  An object of class `umg`.

- row.names:

  Unused; present for S3 consistency.

- optional:

  Unused; present for S3 consistency.

- what:

  `"edges"` (default) returns one row per edge with columns `from`,
  `to`, `kind`, `label`, and `fixed`; `"vertices"` returns one row per
  vertex with columns `name`, `label`, `observed`, `support`, `role`,
  `dist`, `fill`, and `annot`.

- ...:

  Ignored.

## Value

A data frame.

## Examples

``` r
as.data.frame(umg_factor("F", paste0("y", 1:3)))
#>   from to kind          label fixed
#> 1    F y1  dep                    1
#> 2    F y2  dep $\\lambda_{2}$    NA
#> 3    F y3  dep $\\lambda_{3}$    NA
as.data.frame(umg_factor("F", paste0("y", 1:3)), what = "vertices")
#>   name  label observed    support role      dist fill annot
#> 1    F  $F_i$    FALSE continuous   rv N(0, psi) <NA>  <NA>
#> 2   y1 $y1_i$     TRUE continuous   rv      <NA> <NA>  <NA>
#> 3   y2 $y2_i$     TRUE continuous   rv      <NA> <NA>  <NA>
#> 4   y3 $y3_i$     TRUE continuous   rv      <NA> <NA>  <NA>
```
