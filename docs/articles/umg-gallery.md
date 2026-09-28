# A Gallery of Model Families in the UMG Grammar

Each model below is one line of code. The point of the gallery is that
adopting the grammar for a new model is a matter of editing a near
neighbour rather than starting from the definition. Every builder
returns a `umg` object that passes
[`umg_validate()`](https://hsiutingyu.github.io/umg/reference/umg_validate.md)
by construction and can be re-rendered with
[`plot()`](https://rdrr.io/r/graphics/plot.default.html),
[`umg_ggplot()`](https://hsiutingyu.github.io/umg/reference/umg_ggplot.md),
[`umg_to_tikz()`](https://hsiutingyu.github.io/umg/reference/umg_to_tikz.md),
or
[`umg_to_dot()`](https://hsiutingyu.github.io/umg/reference/umg_to_dot.md).

## Measurement models

### Reflective factor (CFA)

``` r
plot(umg_factor("F", paste0("y", 1:5)))
```

![](umg-gallery_files/figure-html/cfa-1.png)

### Bifactor

``` r
plot(umg_bifactor(paste0("y", 1:6),
                  groups = list(g1 = paste0("y", 1:3),
                                g2 = paste0("y", 4:6))))
```

![](umg-gallery_files/figure-html/bifactor-1.png)

### Second-order factor

``` r
plot(umg_secondorder(list(F1 = paste0("y", 1:3),
                          F2 = paste0("y", 4:6),
                          F3 = paste0("y", 7:9))))
```

![](umg-gallery_files/figure-html/secondorder-1.png)

### Exploratory SEM (full cross-loadings)

``` r
plot(umg_esem(c("F1", "F2"), paste0("y", 1:6)))
```

![](umg-gallery_files/figure-html/esem-1.png)

### Formative measurement and MIMIC

``` r
plot(umg_formative(paste0("x", 1:4), outcomes = c("y1", "y2")))
```

![](umg-gallery_files/figure-html/formative-1.png)

``` r
plot(umg_mimic(c("age", "sex"), paste0("y", 1:4)))
```

![](umg-gallery_files/figure-html/formative-2.png)

## Item response models

``` r
plot(umg_irt("2PL"))
```

![](umg-gallery_files/figure-html/irt-1.png)

``` r
plot(umg_irt("graded"))     # graded response model
```

![](umg-gallery_files/figure-html/irt-2.png)

``` r
plot(umg_irt("2PL", n_dim = 2))  # multidimensional IRT
```

![](umg-gallery_files/figure-html/irt-3.png)

The diagnostic classification model combines latent categorical
attributes with the crossed-plate measurement structure:

``` r
Q <- rbind(c(1, 1, 0, 0, 1, 0),
           c(0, 1, 1, 0, 0, 1),
           c(0, 0, 1, 1, 1, 1))
plot(umg_dcm(Q))
```

![](umg-gallery_files/figure-html/dcm-1.png)

## Hierarchy, growth, and longitudinal models

``` r
plot(umg_growth(4))
```

![](umg-gallery_files/figure-html/growth-1.png)

``` r
plot(umg_riclpm(waves = 4))   # random-intercept cross-lagged panel
```

![](umg-gallery_files/figure-html/growth-2.png)

## Mixtures

A growth mixture model is the composition of a growth motif and a
mixture wrapper:

``` r
plot(umg_mixture(umg_growth(4), targets = c("I", "S")))
```

![](umg-gallery_files/figure-html/gmm-1.png)

``` r
plot(umg_lca(paste0("u", 1:5)))   # latent class analysis
```

![](umg-gallery_files/figure-html/gmm-2.png)

## Networks

``` r
plot(umg_network(paste0("x", 1:5)))
```

![](umg-gallery_files/figure-html/network-1.png)

## General SEM assembler

When no single-purpose motif fits, assemble a model from a measurement
and a structural specification:

``` r
m <- umg_sem(
  measurement = list(F1 = paste0("y", 1:3),
                     F2 = paste0("y", 4:6),
                     F3 = paste0("y", 7:9)),
  structural  = list(c("F1", "F3"), c("F2", "F3"))
)
plot(m)
```

![](umg-gallery_files/figure-html/sem-1.png)

## Causal license: the badge

``` r
plot(umg_mediation(confounder = TRUE, badge = "structural"))
```

![](umg-gallery_files/figure-html/badge-1.png)
