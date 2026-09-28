# Generate exploratory display scaffolds from a UMG

Implements the model-data duality of the UMG grammar (article, Table 3):
each motif in the diagram induces a canonical exploratory display. Given
a UMG and a data frame, the function returns a named list of ggplot
objects: faceted panels for plates whose index variable is found in the
data, spaghetti plots for random-coefficient motifs, scatter plots for
dep edges between observed continuous vertices, latent-score
distributions, mixture densities, empirical response curves, and
residual correlation heat maps. The scaffolds are intentionally minimal;
they are starting points for exploration, not finished graphics.

## Usage

``` r
umg_eda_scaffold(model, data, id = NULL, time = NULL)
```

## Arguments

- model:

  An object of class `umg`.

- data:

  A data frame containing the observed vertices.

- id:

  Optional name of the cluster identifier column for spaghetti plots.

- time:

  Optional name of the within-cluster covariate (x axis for spaghetti
  plots).

## Value

A named list of ggplot objects (possibly empty).

## Examples

``` r
set.seed(1)
m <- umg_factor("F", paste0("y", 1:4))
d <- as.data.frame(matrix(rnorm(400), ncol = 4,
                          dimnames = list(NULL, paste0("y", 1:4))))
umg_eda_scaffold(m, d)
#> $score_F

#> 
#> $resid_heatmap

#> 
```
