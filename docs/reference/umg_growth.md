# Latent growth-curve motif

Builds a latent growth model: a latent intercept factor and a latent
slope factor over a set of manifest repeated measures, with fixed unit
loadings from the intercept and fixed time-score loadings from the
slope, and an intercept–slope covariance.

## Usage

``` r
umg_growth(
  occasions = 4,
  times = NULL,
  outcome = "y",
  plate_index = "i = 1, ..., N"
)
```

## Arguments

- occasions:

  Number of repeated measures (\>= 3).

- times:

  Optional numeric time scores (defaults to 0, 1, ..., `occasions - 1`).

- outcome:

  Stem for the manifest outcome names (e.g. `"y"`).

- plate_index:

  Index label for the person plate.

## Value

An object of class `umg`.

## Examples

``` r
plot(umg_growth(4))
```
