# Build a UMG from a blavaan model

Translates a fitted Bayesian structural equation model from the blavaan
package into a UMG. The graph topology is identical to that of the
frequentist
[`umg_from_lavaan()`](https://hsiutingyu.github.io/umg/reference/umg_from_lavaan.md)
translation; what differs is the interpretive reading, since every free
parameter carries a prior. The construction makes literal the article's
claim that the Bayesian and frequentist forms of a model are the same
diagram differing only in which vertices have been prior-closed.

## Usage

``` r
umg_from_blavaan(object, plate_index = "i = 1, ..., N")
```

## Arguments

- object:

  A fitted blavaan object.

- plate_index:

  Index label for the person plate.

## Value

An object of class `umg`.
