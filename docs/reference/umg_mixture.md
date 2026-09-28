# Add a finite-mixture wrapper to an existing UMG

Promotes a set of parameter or latent vertices to class-varying
quantities by adding a latent class vertex with mixing edges into them,
implementing the mixture move described in the accompanying article. The
latent growth model of
[`umg_growth()`](https://hsiutingyu.github.io/umg/reference/umg_growth.md)
wrapped this way becomes a growth mixture model.

## Usage

``` r
umg_mixture(model, targets, class = "c", plate = NULL)
```

## Arguments

- model:

  An object of class `umg`.

- targets:

  Character vector of vertex names the class selects.

- class:

  Name of the latent class vertex to add.

- plate:

  Optional name of an existing plate to add the class vertex to
  (defaults to the first plate, typically the person plate).

## Value

An object of class `umg`.

## Examples

``` r
g <- umg_growth(4)
umg_mixture(g, targets = c("I", "S"))
#> Unified Model Graph (statistical badge)
#>   vertices: 8 | edges: 12 | plates: 1 
#>   edge kinds: cov=1, dep=9, mix=2 
```
