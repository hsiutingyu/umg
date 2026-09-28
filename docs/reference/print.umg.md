# Print a Unified Model Graph

Compact console summary of a `umg` object: the interpretive badge, the
vertex/edge/plate counts, and a tally of edge kinds.

## Usage

``` r
# S3 method for class 'umg'
print(x, ...)
```

## Arguments

- x:

  An object of class `umg`.

- ...:

  Further arguments passed to or from other methods (currently unused).

## Value

The model `x`, invisibly.

## Examples

``` r
print(umg_factor("F", paste0("y", 1:3)))
#> Unified Model Graph (statistical badge)
#>   vertices: 4 | edges: 3 | plates: 1 
#>   edge kinds: dep=3 
```
