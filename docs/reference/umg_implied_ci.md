# Enumerate basis-set implied conditional independencies

Returns the set of conditional independencies that the model implies
under the local Markov property: each vertex is independent of its
non-descendants given its parents in the directed subgraph. These are
the testable implications a researcher can check against the data before
trusting the specification.

## Usage

``` r
umg_implied_ci(model, observed_only = TRUE)
```

## Arguments

- model:

  An object of class `umg`.

- observed_only:

  Logical; restrict the statements to those that are directly testable
  (default `TRUE`), meaning that both vertices *and every vertex in the
  conditioning set* are observed. Statements conditioned on latent
  vertices are implications of the model but cannot be checked against
  data directly; set `observed_only = FALSE` to list them as well.

## Value

A data frame with columns `x`, `y`, and `given` (a comma-separated
conditioning set), one row per implied independence. Independence is
symmetric, so each statement is listed once, in canonical form: `x`
precedes `y` in the model's vertex order, and the conditioning set is
listed in vertex order.

## Examples

``` r
umg_implied_ci(umg_mediation(direct = FALSE))
#>   x y given
#> 1 X Y     M
```
