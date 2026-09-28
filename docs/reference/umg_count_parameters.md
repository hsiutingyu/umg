# Graphical parameter count (t-rule)

Applies the classical counting rule for covariance-structure models: a
model can be identified only if the number of free parameters does not
exceed the number of distinct pieces of information the observed
variables supply. The count is read from the diagram by tallying free
`dep` edges, free `cov` edges, and vertex variances against the number
of non-redundant observed (co)variances. The rule supplies a necessary,
not sufficient, condition; a non-negative degrees of freedom does not
guarantee identification.

## Usage

``` r
umg_count_parameters(model, meanstructure = FALSE, n_means = NULL)
```

## Arguments

- model:

  An object of class `umg`.

- meanstructure:

  Logical; include the observed means in the information count (`p`
  additional moments) and the free intercepts/means in the parameter
  count (default `FALSE`). See Details for how the free means are
  counted.

- n_means:

  Optional integer overriding the automatic count of free mean-structure
  parameters when `meanstructure = TRUE`; ignored otherwise.

## Value

A list with the data information count, the free-parameter breakdown,
the total, the implied degrees of freedom, and a logical element
`applicable`. The rule counts second-order moments and therefore applies
only to models whose random vertices are all continuous; when the model
contains a categorical random vertex (mixtures, latent classes, IRT,
DCM), `applicable` is `FALSE`, the counts are returned as read but the
degrees of freedom are set to `NA`, and a warning is issued.

## Details

With `meanstructure = TRUE`, the free mean-structure parameters are
counted as follows. If every random vertex carries a mean annotation of
the form `mean = free`, `mean = 0`, or `mean = <value>` in its `annot`
field (as written by
[`umg_from_lavaan()`](https://hsiutingyu.github.io/umg/reference/umg_from_lavaan.md)
from a fit with a mean structure), the count is the number of vertices
annotated `mean = free`. Otherwise the diagram does not carry intercept
fixing, and the rule assumes the growth-model convention: the indicators
of latent factors have intercepts fixed at zero, so the free means are
the means of the latent source vertices (latent random vertices without
an incoming directed edge) plus the intercepts of the observed vertices
that are not regressed on a latent vertex. This reproduces lavaan's
`growth()` count (for a linear growth model over four occasions, 14
moments, 9 free parameters, 5 degrees of freedom). For other conventions
supply `n_means`: for a CFA fitted with free observed intercepts and
zero latent means, `n_means = p` (the number of observed vertices), in
which case the mean structure is saturated and the degrees of freedom
are unchanged.

## Examples

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
#> 
umg_count_parameters(umg_growth(4), meanstructure = TRUE)  # df = 5
#> $data_information
#> [1] 14
#> 
#> $free
#> $free$loadings_regressions
#> [1] 0
#> 
#> $free$covariances
#> [1] 1
#> 
#> $free$variances
#> [1] 6
#> 
#> $free$means
#> [1] 2
#> 
#> 
#> $free_total
#> [1] 9
#> 
#> $df
#> [1] 5
#> 
#> $applicable
#> [1] TRUE
#> 
```
