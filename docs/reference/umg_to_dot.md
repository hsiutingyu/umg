# Export a UMG as Graphviz DOT code

Generates a directed-graph description in the Graphviz DOT language.
Node shape encodes support and inferential role, fill encodes
observability, plates become `cluster` subgraphs (nested clusters for
nested plates), and the four edge kinds are rendered with distinct
arrowheads and line styles. The output can be rendered by any Graphviz
engine or by
[`umg_render_dot()`](https://hsiutingyu.github.io/umg/reference/umg_render_dot.md).

## Usage

``` r
umg_to_dot(model, file = NULL, rankdir = c("TB", "LR"), theme = umg_theme())
```

## Arguments

- model:

  An object of class `umg`.

- file:

  Optional path; when supplied, the DOT code is written there and the
  path returned invisibly.

- rankdir:

  Graphviz layout direction: `"TB"` (default) or `"LR"`.

- theme:

  A `umg_theme` controlling fills.

## Value

A character vector of DOT code (invisibly when `file` is supplied).

## Examples

``` r
cat(umg_to_dot(umg_factor("F", paste0("y", 1:3))), sep = "\n")
#> digraph UMG {
#>   graph [rankdir=TB, compound=true];
#>   node [fontname="sans"];
#>   subgraph "cluster_person" {
#>     label="i = 1, ..., N"; style=rounded; color="gray30";
#>       "F" [label="F_i", shape=circle, style=filled, fillcolor="white"];
#>       "y1" [label="y1_i", shape=circle, style=filled, fillcolor="gray85"];
#>       "y2" [label="y2_i", shape=circle, style=filled, fillcolor="gray85"];
#>       "y3" [label="y3_i", shape=circle, style=filled, fillcolor="gray85"];
#>   }
#>   "F" -> "y1" [arrowhead=normal, label="1"];
#>   "F" -> "y2" [arrowhead=normal, label="lambda_{2}"];
#>   "F" -> "y3" [arrowhead=normal, label="lambda_{3}"];
#> }
```
