# Build a UMG from a lavaan model

Translates a lavaan parameter table into a UMG: latent variables (`=~`
left-hand sides) become latent continuous vertices, observed indicators
become observed continuous vertices, loadings and regressions become
`dep` edges, off-diagonal `~~` rows become `cov` edges, and diagonal
`~~` rows are carried as variance annotations. Intercept and mean rows
(`~1`) are carried as mean annotations on the vertex (`mean = free`,
`mean = 0`, `mean = <value>`, or `mean = fixed` when lavaan fixes the
mean at a sample value, as for exogenous covariates under
`fixed.x = TRUE`), so that a model's mean structure survives the round
trip through
[`umg_to_lavaan()`](https://hsiutingyu.github.io/umg/reference/umg_to_lavaan.md).
A single person plate is added over all random vertices, making explicit
the replication that classic SEM diagrams leave implicit.

## Usage

``` r
umg_from_lavaan(object, plate_index = "i = 1, ..., N", bayesian = FALSE)
```

## Arguments

- object:

  A fitted lavaan object, or a lavaan model syntax string (which is then
  lavaanified without fitting).

- plate_index:

  Index label for the person plate.

- bayesian:

  Logical; if `TRUE`, free parameters are rendered in their prior-closed
  (Bayesian) form. Defaults to `FALSE`. Used by
  [`umg_from_blavaan()`](https://hsiutingyu.github.io/umg/reference/umg_from_blavaan.md).

## Value

An object of class `umg`.
