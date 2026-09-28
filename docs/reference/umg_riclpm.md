# Random-intercept cross-lagged panel model (RI-CLPM) motif

Builds the random-intercept cross-lagged panel model of Hamaker, Kuiper,
and Grasman (2015) for two constructs measured over several waves.
Stable between-person differences are absorbed by two random-intercept
factors, while autoregressive and cross-lagged paths operate on the
within-person components, the decomposition that distinguishes the
RI-CLPM from the traditional cross-lagged panel model.

## Usage

``` r
umg_riclpm(waves = 4, x = "x", y = "y", plate_index = "i = 1, ..., N")
```

## Arguments

- waves:

  Number of measurement occasions (\>= 2).

- x, y:

  Stems for the two observed construct names.

- plate_index:

  Index label for the person plate.

## Value

An object of class `umg`.

## Examples

``` r
plot(umg_riclpm(waves = 4))
```
