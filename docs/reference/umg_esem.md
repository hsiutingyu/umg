# Exploratory structural equation model motif

Builds an ESEM measurement block in which every factor loads on every
indicator, the defining feature that distinguishes ESEM from the zero
cross-loadings of confirmatory factor analysis. Factor variances are
fixed to one for scaling, as rotation determines the loading pattern.

## Usage

``` r
umg_esem(
  factors = c("F1", "F2"),
  indicators = paste0("y", 1:6),
  plate_index = "i = 1, ..., N"
)
```

## Arguments

- factors:

  Character vector of factor names.

- indicators:

  Character vector of indicator names.

- plate_index:

  Index label for the person plate.

## Value

An object of class `umg`.

## Examples

``` r
plot(umg_esem(c("F1", "F2"), paste0("y", 1:6)))
```
