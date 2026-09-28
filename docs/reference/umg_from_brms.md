# Build a UMG from a brms model

Translates a Bayesian multilevel model fitted with brms into a
nested-plate UMG. The random-effect structure is parsed from the model
formula with the same engine as
[`umg_from_lmer()`](https://hsiutingyu.github.io/umg/reference/umg_from_lmer.md),
and the fixed-effect population parameters are rendered in their
prior-closed (Bayesian) form, consistent with the article's treatment of
priors as parameter promotion.

## Usage

``` r
umg_from_brms(object, data = NULL)
```

## Arguments

- object:

  A fitted `brmsfit` object, or a model formula using lme4-style
  random-effect syntax.

- data:

  Optional data frame; only used to label index sizes.

## Value

An object of class `umg`.
