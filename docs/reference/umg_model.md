# Assemble and validate a Unified Model Graph

Assemble and validate a Unified Model Graph

## Usage

``` r
umg_model(
  nodes,
  edges,
  plates = list(),
  badge = c("statistical", "structural"),
  validate = TRUE
)
```

## Arguments

- nodes:

  List of `umg_node` objects.

- edges:

  List of `umg_edge` objects.

- plates:

  List of `umg_plate` objects (may be empty).

- badge:

  Interpretive mode: `"statistical"` (default) or `"structural"`.
  Structural diagrams license causal (do-calculus) reading; statistical
  diagrams do not.

- validate:

  Logical; run well-formedness checks W1-W6 (default `TRUE`).

## Value

An object of class `umg`.

## See also

[`umg_validate()`](https://hsiutingyu.github.io/umg/reference/umg_validate.md),
[`plot.umg()`](https://hsiutingyu.github.io/umg/reference/plot.umg.md),
[`umg_to_tikz()`](https://hsiutingyu.github.io/umg/reference/umg_to_tikz.md)

## Examples

``` r
m <- umg_model(
  nodes = list(
    umg_node("eta", "$\\eta_i$", observed = FALSE, dist = "N(0, psi)"),
    umg_node("y1", "$y_{1i}$", observed = TRUE),
    umg_node("y2", "$y_{2i}$", observed = TRUE)
  ),
  edges = list(
    umg_edge("eta", "y1", "dep", fixed = 1),
    umg_edge("eta", "y2", "dep", label = "$\\lambda_2$")
  ),
  plates = list(umg_plate("person", c("eta", "y1", "y2"),
                          "i = 1, ..., N"))
)
```
