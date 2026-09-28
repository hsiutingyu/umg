# Build a UMG from an lme4 formula

Parses an lme4-style mixed-model formula and constructs the nested-plate
UMG: the outcome and within-cluster covariates sit in the inner
(occasion) plate, random coefficients are latent continuous vertices in
the cluster plate, their population means are parameter vertices outside
all plates (the parameter-promotion rendering of fixed vs. random
effects), and random-effect covariances appear as `cov` edges.

## Usage

``` r
umg_from_lmer(formula, data = NULL)
```

## Arguments

- formula:

  An lme4 model formula, e.g. `Reaction ~ Days + (Days | Subject)`.

- data:

  Optional data frame; only used to label index sizes.

## Value

An object of class `umg`.
