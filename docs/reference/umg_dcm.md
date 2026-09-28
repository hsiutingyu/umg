# Diagnostic classification model (DCM) motif

Builds a diagnostic classification (cognitive diagnosis) model: several
binary latent attributes (latent categorical vertices) govern, through a
Q-matrix, the observed item responses at the crossing of person and item
plates. Item parameters are fixed unknowns in the item plate. This
combines a latent categorical structure with the crossed-plate
measurement form, a structure no single classic convention can draw.

## Usage

``` r
umg_dcm(Q = NULL, attr_cov = TRUE, plate_index = "i = 1, ..., N")
```

## Arguments

- Q:

  A K-by-J 0/1 Q-matrix: rows are attributes, columns are items;
  `Q[k, j] = 1` if item `j` requires attribute `k`. Note that this is
  the transpose of the J-by-K (items-by-attributes) layout used by, for
  example, the GDINA and CDM packages; a warning is issued when the
  supplied matrix has at least as many rows as columns, the usual sign
  of the transposed convention. Because the diagram shows the generic
  response vertex `u_ij` rather than per-item vertices, the Q-matrix is
  collapsed to the attribute level: attribute `k` points at `u` when at
  least one item requires it. Defaults to a 3-attribute, 6-item example.

- attr_cov:

  Logical; draw pairwise covariance edges among the latent attributes
  (default `TRUE`), reflecting the saturated (or higher-order) attribute
  distribution that standard DCMs assume. Set to `FALSE` to draw
  independent attributes.

- plate_index:

  Index label for the person plate.

## Value

An object of class `umg`.

## Examples

``` r
Q <- rbind(c(1,1,0,0,1,0), c(0,1,1,0,0,1), c(0,0,1,1,1,1))
plot(umg_dcm(Q))
```
