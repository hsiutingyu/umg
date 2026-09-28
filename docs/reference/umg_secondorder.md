# Second-order factor motif

Builds a hierarchical factor model: a single second-order factor with
directed paths to several first-order factors, each of which loads on a
block of observed indicators. The second-order factor explains the
covariation among the first-order factors.

## Usage

``` r
umg_secondorder(groups, general = "g", plate_index = "i = 1, ..., N")
```

## Arguments

- groups:

  Named list mapping each first-order factor name to its indicator
  names.

- general:

  Name of the second-order factor.

- plate_index:

  Index label for the person plate.

## Value

An object of class `umg`.

## Examples

``` r
plot(umg_secondorder(list(F1 = paste0("y", 1:3),
                          F2 = paste0("y", 4:6),
                          F3 = paste0("y", 7:9))))
```
