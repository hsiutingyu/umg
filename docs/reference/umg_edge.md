# Create a UMG edge

Create a UMG edge

## Usage

``` r
umg_edge(
  from,
  to,
  kind = c("dep", "cov", "det", "mix"),
  label = "",
  fixed = NULL,
  aggregate = FALSE
)
```

## Arguments

- from, to:

  Vertex names (character scalars).

- kind:

  Edge kind: `"dep"` (stochastic dependence), `"cov"` (symmetric
  covariance), `"det"` (deterministic assignment), or `"mix"` (mixture
  selection from a categorical vertex).

- label:

  Optional parameter label (e.g., `"$\\lambda_2$"`); an edge label is
  shorthand for a parameter vertex (parameter promotion; see the
  accompanying article, Section 4.5).

- fixed:

  Optional fixed value (e.g., `1` for a scaling loading).

- aggregate:

  Logical; `TRUE` marks a deterministic (`det`) edge as an aggregation
  over a replicated index, for example a cluster mean computed from
  occasion-level observations. Such an edge runs from a vertex inside a
  plate to a vertex outside it, which the index-licensing rule W5 would
  otherwise refuse (see
  [`umg_validate()`](https://hsiutingyu.github.io/umg/reference/umg_validate.md));
  marking it `aggregate = TRUE` exempts it from that rule. Only
  meaningful for `det` edges; default `FALSE`.

## Value

An object of class `umg_edge`.

## Examples

``` r
umg_edge("eta1", "y1", kind = "dep", fixed = 1)
#> $from
#> [1] "eta1"
#> 
#> $to
#> [1] "y1"
#> 
#> $kind
#> [1] "dep"
#> 
#> $label
#> [1] ""
#> 
#> $fixed
#> [1] 1
#> 
#> $aggregate
#> [1] FALSE
#> 
#> attr(,"class")
#> [1] "umg_edge"
umg_edge("eta1", "eta2", kind = "cov", label = "$\\psi_{21}$")
#> $from
#> [1] "eta1"
#> 
#> $to
#> [1] "eta2"
#> 
#> $kind
#> [1] "cov"
#> 
#> $label
#> [1] "$\\psi_{21}$"
#> 
#> $fixed
#> NULL
#> 
#> $aggregate
#> [1] FALSE
#> 
#> attr(,"class")
#> [1] "umg_edge"
umg_edge("y", "ybar", kind = "det", aggregate = TRUE)
#> $from
#> [1] "y"
#> 
#> $to
#> [1] "ybar"
#> 
#> $kind
#> [1] "det"
#> 
#> $label
#> [1] ""
#> 
#> $fixed
#> NULL
#> 
#> $aggregate
#> [1] TRUE
#> 
#> attr(,"class")
#> [1] "umg_edge"
```
