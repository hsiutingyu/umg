# Export a UMG as TikZ code

Generates a `tikzpicture` in the dialect of the umg-style.tex lexicon
distributed with the package (see
`system.file("tikz", "umg-style.tex", package = "umg")`), so that
programmatic diagrams are stylistically identical to hand-written ones.
The output compiles inside any document whose preamble loads TikZ and
inputs umg-style.tex.

## Usage

``` r
umg_to_tikz(model, file = NULL, digits = 2)
```

## Arguments

- model:

  An object of class `umg`; layout is computed if absent.

- file:

  Optional path; when supplied the code is written there.

- digits:

  Coordinate rounding (default 2).

## Value

The TikZ code as a character vector, invisibly when `file` is supplied.
