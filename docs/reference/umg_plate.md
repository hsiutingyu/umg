# Create a UMG plate

Plates encode exchangeable replication; nested plates encode hierarchy
and overlapping plates encode crossing.

## Usage

``` r
umg_plate(name, members, index, parent = NULL)
```

## Arguments

- name:

  Plate identifier.

- members:

  Character vector of vertex names in the plate scope.

- index:

  Index label, e.g. `"i = 1, ..., N"`.

- parent:

  Optional name of the enclosing plate (nesting).

## Value

An object of class `umg_plate`.

## Examples

``` r
umg_plate("person", c("eta1", "y1"), index = "i = 1, ..., N")
#> $name
#> [1] "person"
#> 
#> $members
#> [1] "eta1" "y1"  
#> 
#> $index
#> [1] "i = 1, ..., N"
#> 
#> $parent
#> NULL
#> 
#> attr(,"class")
#> [1] "umg_plate"
```
