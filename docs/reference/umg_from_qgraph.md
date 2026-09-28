# Build a UMG from a qgraph object or weighted adjacency matrix

Translates a network-psychometric object into a Gaussian-graphical UMG.
A qgraph object is reduced to its weights matrix; a plain numeric matrix
is treated directly as a (partial) association matrix. Nonzero
off-diagonal entries become symmetric `cov` edges among observed
continuous vertices. As the article notes, the UMG displays an estimated
network but does not by itself specify it, since the structure is a
picture of fitted quantities.

## Usage

``` r
umg_from_qgraph(object, threshold = 0, plate_index = "i = 1, ..., N")
```

## Arguments

- object:

  A `qgraph` object, or a square numeric weights matrix.

- threshold:

  Absolute-value cutoff below which an edge is omitted (default `0`,
  i.e. keep every nonzero entry).

- plate_index:

  Index label for the person plate.

## Value

An object of class `umg`.
