# Validate well-formedness of a UMG

Checks the well-formedness rules of the UMG grammar: W1 acyclicity of
the directed (dep/det/mix) subgraph; W2 every source vertex is a
parameter, a constant, or carries an unconditional distribution
annotation; W3 covariance edges join random vertices only; W4 mixing
edges originate from latent categorical random vertices and never target
observed vertices; W5 plates are coherent with the index structure (see
Details); W6 edge endpoints refer to declared vertices. Rules are
checked in linear time; violations raise errors, advisory conditions
raise warnings.

## Usage

``` r
umg_validate(model)
```

## Arguments

- model:

  An object of class `umg`.

## Value

Invisibly `TRUE` if all checks pass.

## Details

Rule W5 has four clauses. (a) Plate membership refers to declared
vertices, parents are declared plates, and nesting is acyclic. (b)
Nesting is consistent with membership: every vertex of a plate nested
inside another plate also belongs to the parent plate. (c) Index
licensing: for every `dep` and `det` edge u -\> v, the plates of u are a
subset of the plates of v, so that a quantity replicated over an index
can only feed quantities that are replicated over that index too (an
item parameter may feed a person-by-item response, but not a
person-level ability). A `det` edge created with `aggregate = TRUE` (see
[`umg_edge()`](https://hsiutingyu.github.io/umg/reference/umg_edge.md))
is exempt, because an aggregate such as a cluster mean legitimately
collapses an index. A `cov` edge joins vertices with identical plate
membership. (d) Mixing: a `mix` edge from a class vertex c selects a
class-specific value of its target, so every random vertex whose density
uses that value (every `dep`-child of the target) must be replicated
over the plates of c. The target itself is exempt from clause (c): it
denotes a K-vector from which one element is selected per copy of c, and
typically sits outside the plates of c.
