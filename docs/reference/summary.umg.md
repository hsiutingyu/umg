# Summarise a UMG

Produces a structured summary of a diagram: vertex counts broken down by
observability, support, and inferential role; edge counts by kind; the
plate structure; and a one-line identification snapshot from
[`umg_count_parameters()`](https://hsiutingyu.github.io/umg/reference/umg_count_parameters.md)
and
[`umg_check_scaling()`](https://hsiutingyu.github.io/umg/reference/umg_check_scaling.md).

## Usage

``` r
# S3 method for class 'umg'
summary(object, ...)

# S3 method for class 'summary.umg'
print(x, ...)
```

## Arguments

- object:

  An object of class `umg`.

- ...:

  Ignored.

- x:

  An object of class `summary.umg`.

## Value

An object of class `summary.umg` (a list), printed by its own method.

## Examples

``` r
summary(umg_sem(list(F1 = paste0("y", 1:3), F2 = paste0("y", 4:6)),
                structural = list(c("F1", "F2"))))
#> Unified Model Graph summary (statistical badge)
#> -----------------------------------------------
#> Vertices: 8  (observed rv: 6, latent rv: 2, parameters: 0, constants: 0)
#> Categorical-support vertices: 0
#> Edges: dep=7 
#> Plates: 1 (person)
#> Counting rule: 21 data moments, 13 free parameters, df = 8
```
