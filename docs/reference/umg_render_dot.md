# Render a UMG through DiagrammeR (Graphviz)

Renders the DOT export of a UMG to an interactive HTML widget using
DiagrammeR's Graphviz engine, suitable for notebooks, Shiny, and
rmarkdown HTML output.

## Usage

``` r
umg_render_dot(model, ...)
```

## Arguments

- model:

  An object of class `umg`.

- ...:

  Passed to
  [`umg_to_dot()`](https://hsiutingyu.github.io/umg/reference/umg_to_dot.md).

## Value

A `grViz`/`htmlwidget` object.

## Examples

``` r
umg_render_dot(umg_irt("2PL"))

{"x":{"diagram":"digraph UMG {\n  graph [rankdir=TB, compound=true];\n  node [fontname=\"sans\"];\n  subgraph \"cluster_person\" {\n    label=\"i = 1, ..., N\"; style=rounded; color=\"gray30\";\n      \"theta\" [label=\"theta_i\", shape=circle, style=filled, fillcolor=\"white\"];\n      \"u\" [label=\"u_{ij}\", shape=box, style=filled, fillcolor=\"gray85\"];\n  }\n  subgraph \"cluster_item\" {\n    label=\"j = 1, ..., J\"; style=rounded; color=\"gray30\";\n      \"b\" [label=\"b_j\", shape=diamond, style=filled, fillcolor=\"white\"];\n      \"a\" [label=\"a_j\", shape=diamond, style=filled, fillcolor=\"white\"];\n  }\n  \"theta\" -> \"u\" [arrowhead=normal];\n  \"b\" -> \"u\" [arrowhead=normal];\n  \"a\" -> \"u\" [arrowhead=normal];\n  // note: crossed plates rendered by smallest-enclosing assignment\n}","config":{"engine":"dot","options":null}},"evals":[],"jsHooks":[]}
```
