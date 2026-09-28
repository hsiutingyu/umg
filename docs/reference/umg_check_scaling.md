# Check latent-variable scaling marks

Every latent continuous random vertex must have its scale fixed, either
by a unit-valued outgoing loading (marker method), by a fixed variance
(variance-standardisation method), or, for a formative composite, by a
unit-valued incoming weight from an observed cause (the marker
convention for composites). This function inspects each such vertex and
reports whether a scaling mark is present, exposing the single most
common specification error in latent variable modelling as a missing
mark rather than a nonconvergence.

## Usage

``` r
umg_check_scaling(model)
```

## Arguments

- model:

  An object of class `umg`.

## Value

A data frame with one row per latent continuous random vertex and
columns `vertex`, `scaled` (logical), `via` (the scaling mechanism
detected: `"marker loading"`, `"fixed variance"`, `"marker weight"`, or
`"none"`), and `location_fixed` (logical; informational, `TRUE` when a
constant parent fixes the location).

## Details

A constant parent (a `const` vertex with an edge into the latent vertex)
fixes the *location* of the latent variable, not its scale: it pins the
mean, and a variance can still be traded against the loadings. It is
therefore reported separately in `location_fixed` and does not count as
a scaling mark.

## Examples

``` r
umg_check_scaling(umg_factor("F", paste0("y", 1:3)))
#>   vertex scaled            via location_fixed
#> 1      F   TRUE marker loading          FALSE
umg_check_scaling(umg_formative(paste0("x", 1:3), outcomes = c("y1", "y2")))
#>   vertex scaled           via location_fixed
#> 1      C   TRUE marker weight          FALSE
```
