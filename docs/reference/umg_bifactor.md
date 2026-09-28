# Bifactor measurement motif

Builds a bifactor model: a general factor loading on every indicator
plus one or more orthogonal group factors each loading on a contiguous
block of indicators. This is the representation behind the general
factor of psychopathology and similar structures.

## Usage

``` r
umg_bifactor(indicators, groups, general = "g", plate_index = "i = 1, ..., N")
```

## Arguments

- indicators:

  Character vector of all indicator names.

- groups:

  A list of character vectors; each element names the indicators loading
  on one group factor.

- general:

  Name of the general factor.

- plate_index:

  Index label for the person plate.

## Value

An object of class `umg`.

## Examples

``` r
umg_bifactor(paste0("y", 1:6),
             groups = list(g1 = paste0("y", 1:3),
                           g2 = paste0("y", 4:6)))
#> Unified Model Graph (statistical badge)
#>   vertices: 9 | edges: 12 | plates: 1 
#>   edge kinds: dep=12 
```
