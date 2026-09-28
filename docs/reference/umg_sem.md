# General structural equation model builder

Assembles a complete SEM from a measurement specification and an
optional structural specification, the flexible route when no
single-purpose motif fits. Factors named in `measurement` become latent
continuous vertices; their indicators become observed continuous
vertices with the first loading fixed to one for scaling (unless
`scaling = "variance"`). Structural regressions and covariances are
added as `dep` and `cov` edges respectively.

## Usage

``` r
umg_sem(
  measurement,
  structural = list(),
  covariances = list(),
  scaling = c("marker", "variance"),
  observed = character(0),
  badge = c("statistical", "structural"),
  plate_index = "i = 1, ..., N"
)
```

## Arguments

- measurement:

  Named list mapping each latent factor name to a character vector of
  its indicator names.

- structural:

  Optional list of length-2 character vectors `c(from, to)` giving
  directed regressions among factors and/or observed variables.

- covariances:

  Optional list of length-2 character vectors giving symmetric
  covariance edges.

- scaling:

  `"marker"` (fix first loading to 1, the default) or `"variance"` (fix
  the factor variance to 1; no marker loading). Under variance scaling,
  exogenous factors are annotated `N(0, 1)` and endogenous factors carry
  a fixed unit *residual* variance (`resid var = 1`), matching the
  convention of `lavaan`'s `std.lv = TRUE`, so every factor's scale is
  fixed.

- observed:

  Optional character vector of additional observed variables referenced
  only in `structural`/`covariances`.

- badge:

  `"statistical"` (default) or `"structural"`.

- plate_index:

  Index label for the person plate.

## Value

An object of class `umg`.

## Examples

``` r
m <- umg_sem(
  measurement = list(F1 = c("y1", "y2", "y3"),
                     F2 = c("y4", "y5", "y6")),
  structural  = list(c("F1", "F2"))
)
plot(m)
```
