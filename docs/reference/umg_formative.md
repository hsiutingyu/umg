# Formative (composite) measurement motif

Builds a formative measurement model in which observed indicators are
causes of a composite latent variable, the reverse of the reflective
direction. Because a composite is identified only when it emits to at
least two further quantities, an optional pair of reflective outcome
indicators may be supplied. The scale of the composite is fixed by
default by fixing the weight of the first indicator to 1 (the marker
convention lavaan applies to `<~` composites), so that the motif passes
[`umg_check_scaling()`](https://hsiutingyu.github.io/umg/reference/umg_check_scaling.md).

## Usage

``` r
umg_formative(
  indicators = paste0("x", 1:4),
  composite = "C",
  outcomes = NULL,
  scaling = c("marker", "none"),
  plate_index = "i = 1, ..., N"
)
```

## Arguments

- indicators:

  Character vector of formative indicator (cause) names.

- composite:

  Name of the composite latent variable.

- outcomes:

  Optional character vector of reflective outcome indicators emitted by
  the composite (recommended for identification, typically \>= 2).

- scaling:

  `"marker"` (the default) fixes the weight of the first indicator to 1;
  `"none"` leaves every weight free, which draws the composite without a
  scaling mark (it is then reported as unscaled by
  [`umg_check_scaling()`](https://hsiutingyu.github.io/umg/reference/umg_check_scaling.md)).

- plate_index:

  Index label for the person plate.

## Value

An object of class `umg`.

## Examples

``` r
plot(umg_formative(paste0("x", 1:4), outcomes = c("y1", "y2")))
```
