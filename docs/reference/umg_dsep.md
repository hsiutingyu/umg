# Test d-separation in a UMG

Reads a conditional-independence claim off the diagram by the
d-separation criterion. Covariance edges are treated as latent common
causes (the projection of an acyclic directed mixed graph onto a DAG),
so that an unanalysed association behaves as a fork. The test
generalises the vanishing-tetrad reasoning of the factor-analytic
tradition and supplies the model's testable implications.

## Usage

``` r
umg_dsep(model, x, y, given = character(0))
```

## Arguments

- model:

  An object of class `umg`.

- x, y:

  Vertex names whose separation is queried.

- given:

  Character vector of conditioning vertices (default none); may not
  contain `x` or `y`.

## Value

`TRUE` if `x` and `y` are d-separated given `given`, `FALSE` otherwise.

## Details

The test is carried out by the moralized ancestral graph criterion
(Lauritzen, Dawid, Larsen, & Leimer, 1990), which is exact and runs in
time linear in the size of the graph, so dense diagrams (for example,
saturated network models) are handled without approximation.

## Examples

``` r
m <- umg_mediation(direct = FALSE)
umg_dsep(m, "X", "Y")             # FALSE: connected through M
#> [1] FALSE
umg_dsep(m, "X", "Y", given = "M")  # TRUE: blocked by M
#> [1] TRUE
```
