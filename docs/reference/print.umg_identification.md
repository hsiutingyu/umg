# Print a UMG identification summary

Formats the components collected by
[`umg_identify()`](https://hsiutingyu.github.io/umg/reference/umg_identify.md)
into a compact report: latent scaling status, the counting-rule degrees
of freedom, any label-switching indeterminacy, and the number of implied
conditional independencies.

## Usage

``` r
# S3 method for class 'umg_identification'
print(x, ...)
```

## Arguments

- x:

  An object of class `umg_identification`.

- ...:

  Further arguments passed to or from other methods (currently unused).

## Value

The object `x`, invisibly.

## Examples

``` r
print(umg_identify(umg_factor("F", paste0("y", 1:6))))
#> UMG identification summary
#> --------------------------
#> Latent scaling: 1 latent continuous vertex(es); all scaled
#> Counting rule: 21 data moments, 12 free parameters, df = 9
#> Implied conditional independencies (observed): 0
#> Note: necessary conditions only; not a formal identification proof.
```
