# Generate lavaan model syntax from a UMG

Emits lavaan model syntax from a diagram, the inverse of
[`umg_from_lavaan()`](https://hsiutingyu.github.io/umg/reference/umg_from_lavaan.md).
The translation uses an explicit, documented convention. A directed
(`dep`) edge from a latent vertex to an observed vertex is a measurement
loading (`=~`); every other directed edge is a regression (`~`), so that
observed-to-observed paths, observed-to-latent causes (as in MIMIC), and
latent-to-latent structural paths are all written with `~`. Symmetric
(`cov`) edges become covariances (`~~`). Fixed edge values are written
as `value * variable`; free edges are left for lavaan to estimate, and
residual variances are left implicit. A vertex carrying a mean
annotation in its `annot` field (as written by
[`umg_from_lavaan()`](https://hsiutingyu.github.io/umg/reference/umg_from_lavaan.md)
from a fit with a mean structure) yields an intercept line:
`mean = free` becomes `v ~ 1`, and `mean = <value>` becomes
`v ~ <value>*1`; `mean = fixed` (a mean fixed at a sample value, as for
exogenous covariates under `fixed.x = TRUE`) emits nothing, because a
refit fixes it the same way. A growth model therefore round-trips with
its mean structure intact, whether refitted with
[`lavaan::growth()`](https://rdrr.io/pkg/lavaan/man/growth.html) or with
[`lavaan::cfa()`](https://rdrr.io/pkg/lavaan/man/cfa.html).

## Usage

``` r
umg_to_lavaan(model, file = NULL)
```

## Arguments

- model:

  An object of class `umg`.

- file:

  Optional path; when supplied the syntax is written there and the path
  is returned invisibly.

## Value

A single character string of lavaan syntax (invisibly when `file` is
supplied).

## Details

The convention cannot recover a measurement interpretation of a
latent-to-latent relation (for example a second-order factor loading on
first-order factors), which is written as a latent regression; a message
flags this case so the relevant lines can be changed from `~` to `=~` by
hand if a higher-order measurement model is intended. Mixing (`mix`) and
deterministic (`det`) edges, and the categorical latent structure of
mixture and diagnostic models, have no basic lavaan syntax and are
omitted with a warning.

## See also

[`umg_from_lavaan()`](https://hsiutingyu.github.io/umg/reference/umg_from_lavaan.md)

## Examples

``` r
cat(umg_to_lavaan(umg_sem(
  measurement = list(F1 = paste0("y", 1:3), F2 = paste0("y", 4:6)),
  structural  = list(c("F1", "F2")))))
#> umg_to_lavaan(): latent-to-latent paths written as regressions ('~'); change to '=~' by hand if a higher-order measurement model is intended.
#> # measurement model
#> F1 =~ 1*y1 + y2 + y3
#> F2 =~ 1*y4 + y5 + y6
#> # structural / regression model
#> F2 ~ F1
```
