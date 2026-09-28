# Identification summary for a UMG

Collects the identification-relevant readings of a diagram into a single
object: scaling-mark checks, the graphical parameter count, the
label-switching flag, and the number of implied conditional
independencies. Printing the object gives a compact report.

## Usage

``` r
umg_identify(model, meanstructure = FALSE, n_means = NULL)
```

## Arguments

- model:

  An object of class `umg`.

- meanstructure, n_means:

  Passed to
  [`umg_count_parameters()`](https://hsiutingyu.github.io/umg/reference/umg_count_parameters.md).

## Value

An object of class `umg_identification`.

## Examples

``` r
umg_identify(umg_factor("F", paste0("y", 1:6)))
#> UMG identification summary
#> --------------------------
#> Latent scaling: 1 latent continuous vertex(es); all scaled
#> Counting rule: 21 data moments, 12 free parameters, df = 9
#> Implied conditional independencies (observed): 0
#> Note: necessary conditions only; not a formal identification proof.
```
