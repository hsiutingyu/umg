# MIMIC (multiple-indicator multiple-cause) motif

Builds a MIMIC model: observed covariates predict a reflective latent
factor that in turn loads on observed indicators. The cause side is
formative and the effect side is reflective, a structure widely used to
model the effect of background variables on a latent trait and to probe
differential item functioning.

## Usage

``` r
umg_mimic(
  causes = c("z1", "z2"),
  indicators = paste0("y", 1:4),
  factor = "F",
  plate_index = "i = 1, ..., N"
)
```

## Arguments

- causes:

  Character vector of observed predictor names.

- indicators:

  Character vector of reflective indicator names.

- factor:

  Name of the latent factor.

- plate_index:

  Index label for the person plate.

## Value

An object of class `umg`.

## Examples

``` r
plot(umg_mimic(c("age", "sex"), paste0("y", 1:4)))
```
