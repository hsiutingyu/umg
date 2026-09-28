# Caterpillar (shrinkage) plot of cluster-level estimates

Renders the caterpillar plot implied by a random-coefficient vertex:
cluster-level estimates ordered by value with optional uncertainty
intervals, the canonical display for inspecting between-cluster
variation and shrinkage. The input is the estimated deviations, which
the modelling package supplies after fitting; the diagram object names
the display, this function draws it.

## Usage

``` r
umg_caterpillar(
  estimates,
  se = NULL,
  level = 0.95,
  title = "Caterpillar plot: cluster estimates"
)
```

## Arguments

- estimates:

  A numeric vector of cluster-level estimates, or a data frame with a
  column `estimate` and optionally `se` and `group`.

- se:

  Optional numeric vector of standard errors (used when `estimates` is a
  numeric vector).

- level:

  Confidence level for the interval (default `0.95`).

- title:

  Plot title.

## Value

A ggplot object.

## Examples

``` r
set.seed(1)
if (requireNamespace("ggplot2", quietly = TRUE))
  umg_caterpillar(rnorm(20), se = runif(20, 0.2, 0.5))
```
