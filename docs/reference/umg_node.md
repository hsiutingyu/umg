# Create a UMG vertex

Vertices are typed on three orthogonal dimensions: observability
(observed vs. latent), support (continuous vs. categorical), and
inferential role (random variable, fixed unknown parameter,
deterministic node, or known constant).

## Usage

``` r
umg_node(
  name,
  label = name,
  observed = FALSE,
  support = c("continuous", "categorical"),
  role = c("rv", "par", "det", "const"),
  dist = NULL,
  fill = NULL,
  annot = NULL
)
```

## Arguments

- name:

  Unique vertex identifier (character scalar).

- label:

  Display label; defaults to `name`. May contain TeX math (e.g.,
  `"$\\eta_{1i}$"`) for TikZ export.

- observed:

  Logical; `TRUE` for observed vertices. Ignored for roles `"par"` and
  `"const"`, which are never observed data.

- support:

  `"continuous"` or `"categorical"`.

- role:

  `"rv"` (random variable), `"par"` (fixed unknown parameter), `"det"`
  (deterministic), or `"const"` (known constant).

- dist:

  Optional distribution annotation (character), e.g. `"N(0, 1)"`.
  Required for source random vertices (rule W2).

- fill:

  Optional fill colour overriding the theme default for this vertex (any
  R colour specification). Useful for highlighting a subset of vertices
  without editing the theme.

- annot:

  Optional free-form annotation string carried with the vertex (e.g., a
  convergence diagnostic such as `"Rhat = 1.00"`). Annotations are
  available to renderers and exporters.

## Value

An object of class `umg_node`.

## Examples

``` r
umg_node("eta1", "$\\eta_{1i}$", observed = FALSE)
#> $name
#> [1] "eta1"
#> 
#> $label
#> [1] "$\\eta_{1i}$"
#> 
#> $observed
#> [1] FALSE
#> 
#> $support
#> [1] "continuous"
#> 
#> $role
#> [1] "rv"
#> 
#> $dist
#> NULL
#> 
#> $fill
#> NULL
#> 
#> $annot
#> NULL
#> 
#> attr(,"class")
#> [1] "umg_node"
umg_node("c", "$c_i$", observed = FALSE, support = "categorical",
         dist = "Categorical(pi)")
#> $name
#> [1] "c"
#> 
#> $label
#> [1] "$c_i$"
#> 
#> $observed
#> [1] FALSE
#> 
#> $support
#> [1] "categorical"
#> 
#> $role
#> [1] "rv"
#> 
#> $dist
#> [1] "Categorical(pi)"
#> 
#> $fill
#> NULL
#> 
#> $annot
#> NULL
#> 
#> attr(,"class")
#> [1] "umg_node"
umg_node("y1", "$y_{1i}$", observed = TRUE, fill = "grey60",
         annot = "reverse-scored")
#> $name
#> [1] "y1"
#> 
#> $label
#> [1] "$y_{1i}$"
#> 
#> $observed
#> [1] TRUE
#> 
#> $support
#> [1] "continuous"
#> 
#> $role
#> [1] "rv"
#> 
#> $dist
#> NULL
#> 
#> $fill
#> [1] "grey60"
#> 
#> $annot
#> [1] "reverse-scored"
#> 
#> attr(,"class")
#> [1] "umg_node"
```
