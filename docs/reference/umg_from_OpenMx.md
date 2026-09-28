# Build a UMG from an OpenMx RAM model

Translates a reticular action model (RAM) fitted or specified with
OpenMx into a UMG. Manifest variables become observed vertices and
latent variables become latent vertices; nonzero entries of the
asymmetric matrix `A` become directed `dep` edges (with fixed values
shown for non-free paths), and off-diagonal entries of the symmetric
matrix `S` become `cov` edges. This exposes the path-diagram content of
a RAM specification in the UMG lexicon.

## Usage

``` r
umg_from_OpenMx(object, plate_index = "i = 1, ..., N")
```

## Arguments

- object:

  An `MxModel` containing RAM matrices `A`, `S`, and `F` (the standard
  `mxModel(type = "RAM")` form).

- plate_index:

  Index label for the person plate.

## Value

An object of class `umg`.
