# Item response theory motif (crossed persons x items)

Builds a unidimensional IRT diagram with crossed person and item plates:
a latent ability in the person plate, item parameters as fixed unknowns
in the item plate, and an observed categorical response at the crossing.

## Usage

``` r
umg_irt(
  model = c("2PL", "1PL", "3PL", "graded", "PCM", "GPCM"),
  ability = "theta",
  n_dim = 1L
)
```

## Arguments

- model:

  Item model. Dichotomous: `"1PL"`, `"2PL"`, `"3PL"`. Polytomous:
  `"graded"` (graded response model, GRM), `"PCM"` (partial credit
  model), `"GPCM"` (generalized partial credit model). The choice
  controls which item-parameter diamonds are drawn (discrimination,
  difficulty/thresholds, guessing).

- ability:

  Name/label stem for the latent ability.

- n_dim:

  Number of latent ability dimensions (\>= 1). With more than one
  dimension the model is multidimensional IRT (MIRT); each ability
  vertex points at the response.

## Value

An object of class `umg`.

## Examples

``` r
plot(umg_irt("2PL"))

plot(umg_irt("graded"))

plot(umg_irt("2PL", n_dim = 2))
```
