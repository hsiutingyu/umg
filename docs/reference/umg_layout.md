# Compute a layered layout for a UMG

Assigns coordinates by longest-path layering on the directed subgraph:
parameters and constants at the top, observed leaves at the bottom,
vertices spread horizontally within layers. Plate rectangles are
computed as padded bounding boxes of their members, with padding growing
by nesting depth so nested plates remain visually distinct. Coordinates
can be overridden by supplying a `coords` data frame, which is the
recommended route for publication figures.

## Usage

``` r
umg_layout(
  model,
  coords = NULL,
  hgap = 1.6,
  vgap = 1.8,
  orientation = c("TB", "LR")
)
```

## Arguments

- model:

  An object of class `umg`.

- coords:

  Optional data frame with columns `name`, `x`, `y` overriding computed
  positions.

- hgap, vgap:

  Horizontal and vertical spacing between vertices.

- orientation:

  Layer direction: `"TB"` (top to bottom, the default) places sources at
  the top and observed leaves at the bottom; `"LR"` lays the layers out
  left to right. `NULL` is treated as `"TB"`.

## Value

The model with a `layout` component added: a data frame of vertex
coordinates and a list of plate rectangles.
