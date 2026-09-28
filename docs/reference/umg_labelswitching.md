# Flag label-switching symmetry in mixtures

Mixture and latent class models are identified only up to a permutation
of the latent classes, the label-switching indeterminacy. This function
reports the latent categorical random vertices whose value permutation
leaves the diagram invariant, making the indeterminacy a visible
property of the specification.

## Usage

``` r
umg_labelswitching(model)
```

## Arguments

- model:

  An object of class `umg`.

## Value

A character vector of latent categorical random vertex names (empty if
the model has no mixture component).

## Examples

``` r
umg_labelswitching(umg_mixture(umg_growth(4), c("I", "S")))
#> [1] "c"
```
