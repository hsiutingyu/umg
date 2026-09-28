# Reading Identification off the Diagram

Because a well-formed UMG determines a likelihood, several necessary
conditions for identification can be read from the picture before any
estimation is attempted. The functions in this vignette operationalise
that idea. None of them replaces a formal identification analysis; each
catches a routine error at the drawing board, where errors are cheapest
to fix.

## Scaling marks for latent variables

Every latent continuous random vertex must have its scale fixed.
[`umg_check_scaling()`](https://hsiutingyu.github.io/umg/reference/umg_check_scaling.md)
reports the mechanism detected for each.

``` r
umg_check_scaling(umg_factor("F", paste0("y", 1:4)))   # marker loading
#>   vertex scaled            via location_fixed
#> 1      F   TRUE marker loading          FALSE
umg_check_scaling(umg_esem("F1", paste0("y", 1:4)))    # fixed variance
#>   vertex scaled            via location_fixed
#> 1     F1   TRUE fixed variance          FALSE
```

A latent vertex reported as `"none"` is the single most common
specification error in latent variable modelling, surfaced as a missing
mark rather than a nonconvergence.

## The counting rule

[`umg_count_parameters()`](https://hsiutingyu.github.io/umg/reference/umg_count_parameters.md)
applies the classical t-rule, comparing free parameters against the
distinct pieces of information the observed variables supply. A
non-negative `df` is necessary, not sufficient.

``` r
umg_count_parameters(umg_factor("F", paste0("y", 1:6)))
#> $data_information
#> [1] 21
#> 
#> $free
#> $free$loadings_regressions
#> [1] 5
#> 
#> $free$covariances
#> [1] 0
#> 
#> $free$variances
#> [1] 7
#> 
#> $free$means
#> [1] 0
#> 
#> 
#> $free_total
#> [1] 12
#> 
#> $df
#> [1] 9
#> 
#> $applicable
#> [1] TRUE
```

## Label switching

Mixture and latent class models are identified only up to a permutation
of the classes.

``` r
umg_labelswitching(umg_mixture(umg_growth(4), c("I", "S")))
#> [1] "c"
```

## Conditional independence and d-separation

[`umg_dsep()`](https://hsiutingyu.github.io/umg/reference/umg_dsep.md)
reads a conditional-independence claim off the diagram. Covariance edges
are treated as latent common causes (the projection of an acyclic
directed mixed graph onto a DAG).

``` r
med <- umg_mediation(direct = FALSE)
umg_dsep(med, "X", "Y")               # FALSE: connected through M
#> [1] FALSE
umg_dsep(med, "X", "Y", given = "M")  # TRUE: blocked by the mediator
#> [1] TRUE
```

The implied independencies of the model (its testable implications) are
enumerated under the local Markov property:

``` r
umg_implied_ci(umg_mediation(direct = FALSE))
#>   x y given
#> 1 X Y     M
```

## A single summary

[`umg_identify()`](https://hsiutingyu.github.io/umg/reference/umg_identify.md)
collects these readings into one printable object.

``` r
umg_identify(umg_factor("F", paste0("y", 1:6)))
#> UMG identification summary
#> --------------------------
#> Latent scaling: 1 latent continuous vertex(es); all scaled
#> Counting rule: 21 data moments, 12 free parameters, df = 9
#> Implied conditional independencies (observed): 0
#> Note: necessary conditions only; not a formal identification proof.
```
