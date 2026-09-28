# Latent class motif

Builds a latent class (or latent profile) model: a latent categorical
class vertex with mixing proportions, predicting a set of observed
indicators. Categorical indicators yield latent class analysis;
continuous indicators yield a latent profile model.

## Usage

``` r
umg_lca(
  indicators = paste0("u", 1:4),
  categorical = TRUE,
  class = "c",
  plate_index = "i = 1, ..., N"
)
```

## Arguments

- indicators:

  Character vector of indicator names.

- categorical:

  Logical; `TRUE` (default) for categorical indicators (LCA), `FALSE`
  for continuous (LPA).

- class:

  Name of the latent class vertex.

- plate_index:

  Index label for the person plate.

## Value

An object of class `umg`.

## Examples

``` r
plot(umg_lca(paste0("u", 1:4)))
```
