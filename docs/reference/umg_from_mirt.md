# Build a UMG from a fitted mirt model

Translates a fitted item response model from the mirt package into a
crossed-plate UMG: latent ability dimensions become latent continuous
vertices in the person plate, the observed responses become an observed
categorical vertex at the crossing of the person and item plates, and
the item parameters become fixed-unknown diamonds in the item plate. The
number of ability dimensions is read from the fitted object; the
item-parameter glyphs are generic (discrimination and location), since
the diagram represents the structure rather than per-item estimates.

## Usage

``` r
umg_from_mirt(object, model = c("2PL", "1PL", "3PL", "graded"))
```

## Arguments

- object:

  A fitted `SingleGroupClass`/`mirt` object, or an integer giving the
  number of latent dimensions (for a quick structural sketch without a
  fit).

- model:

  Item-model label deciding which item-parameter vertices to draw: one
  of `"2PL"`, `"1PL"`, `"3PL"`, `"graded"`. When `object` is a fitted
  mirt model and `model` is not supplied, the item type is read from the
  fitted object (`Rasch` maps to `"1PL"`; `graded`, `grsm`, `gpcm`, and
  `gpcmIRT` map to `"graded"`); an explicit `model` argument overrides
  the fit.

## Value

An object of class `umg`.
