# Mediation motif

Builds an X -\> M -\> Y mediation diagram with an optional direct effect
and an optional latent confounder of the mediator and the outcome. The
interpretive badge controls whether the diagram licenses a causal
reading.

## Usage

``` r
umg_mediation(
  x = "X",
  m = "M",
  y = "Y",
  direct = TRUE,
  confounder = FALSE,
  badge = c("statistical", "structural"),
  plate_index = "i = 1, ..., N"
)
```

## Arguments

- x, m, y:

  Names of the predictor, mediator, and outcome.

- direct:

  Logical; include the direct X -\> Y path (default `TRUE`).

- confounder:

  Logical; include a latent confounder U of M and Y (default `FALSE`).

- badge:

  `"statistical"` or `"structural"`.

- plate_index:

  Index label for the person plate.

## Value

An object of class `umg`.

## Examples

``` r
plot(umg_mediation(confounder = TRUE, badge = "structural"))
```
