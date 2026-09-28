# Reflective factor (measurement) motif

Builds a single-factor reflective measurement model: one latent
continuous factor with directed loadings onto observed continuous
indicators, the first loading fixed to 1 for scaling, residual variances
implied, and a person plate.

## Usage

``` r
umg_factor(
  factor = "F",
  indicators = c("y1", "y2", "y3"),
  loadings = NULL,
  factor_label = NULL,
  indicator_labels = NULL,
  plate_index = "i = 1, ..., N",
  dist = "N(0, psi)"
)
```

## Arguments

- factor:

  Name of the latent factor (character scalar).

- indicators:

  Character vector of indicator names (\>= 2).

- loadings:

  Optional character vector of loading labels for the free loadings (the
  indicators after the first), so of length `length(indicators) - 1`. A
  vector of length `length(indicators)` is also accepted, in which case
  its first element (the fixed marker loading) is ignored. Defaults to
  `lambda[k]`.

- factor_label, indicator_labels:

  Optional display labels.

- plate_index:

  Index label for the person plate.

- dist:

  Distribution annotation for the factor (source vertex).

## Value

An object of class `umg`.

## Examples

``` r
m <- umg_factor("F", c("y1", "y2", "y3"))
plot(m)
```
