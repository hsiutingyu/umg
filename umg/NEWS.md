# umg 0.6.0

Correctness release. The demonstrations prepared for the companion
manuscript (Yu, 2026, "When is a diagram a model?") exercised 0.5.0
against lavaan, lme4, mirt, dagitty, and Graphviz and recorded fourteen
behaviours that were wrong, misleading, or cosmetic. The statistical and
export defects are fixed here; each fix is pinned by a regression test
in `tests/testthat/test-regressions-060.R`. Rendering and design items
(annotation rendering, arrowheads into square vertices, label overlap,
the ESEM rotational constraints, the exogenous-cause covariances of the
MIMIC and formative motifs, and the slope proxy of the EDA scaffold)
are deferred to a later release.

## Well-formedness: rule W5 now checks the index structure

* `umg_validate()` implements the full plate rule. Besides the existing
  coherence checks (members declared, parent declared, nesting
  acyclic), it now refuses (a) a vertex that belongs to a nested plate
  but not to the parent plate ("W5 violated: vertex 'y' is in plate
  'occasion' but not in its parent plate 'cluster'."); (b) a `dep` or
  `det` edge u -> v whose source is replicated over an index the target
  is not (plates(u) must be a subset of plates(v); for example an item
  parameter pointing at a person-level ability); (c) a `cov` edge
  joining vertices with different plate membership; and (d) a `mix`
  edge from a class vertex c that selects a parameter used by a random
  vertex not replicated over the plates of c. The mix target itself is
  exempt from (b): it denotes a K-vector from which one element is
  selected per copy of c. Previously 0.5.0 accepted all of these.
* `umg_edge()` gains `aggregate = FALSE`. A deterministic edge marked
  `aggregate = TRUE` (a cluster mean computed from occasion-level
  observations, say) is exempt from the index-licensing clause, since
  an aggregate legitimately collapses an index. The argument is
  rejected on non-`det` edges.
* Every motif builder and every converter (`umg_from_lavaan()`,
  `umg_from_lmer()`, `umg_from_mirt()`, and the rest) was checked under
  the new rule; all of them validate, so no builder had to change.

## Identification tooling

* `umg_count_parameters(meanstructure = TRUE)` counted one free mean
  per random vertex, so a linear growth model over four occasions
  returned df = 1 where lavaan returns df = 5. The free means are now
  counted as the documentation states: when the vertices carry mean
  annotations (as written by `umg_from_lavaan()` from a fit with a
  mean structure) the vertices annotated `mean = free` are counted;
  otherwise the growth-model convention applies (indicators of latent
  factors have zero intercepts, so the free means are the latent
  source means plus the intercepts of observed vertices not regressed
  on a latent vertex). The Demo.growth model now returns 14 moments,
  9 free parameters, df = 5 from both `umg_from_lavaan(fit)` and
  `umg_growth(4)`. A new argument `n_means` overrides the automatic
  count for other conventions (for a CFA with free observed intercepts
  and zero latent means, `n_means = p` leaves the df unchanged); it is
  also accepted by `umg_identify()`.
* `umg_implied_ci()` returned each symmetric statement twice
  ((x, y | Z) and (y, x | Z)); a one-factor model with four indicators
  listed 12 rows for 6 independencies. Each statement is now listed
  once in canonical form (`x` before `y` in the model's vertex order,
  conditioning set in vertex order), and `print.umg_identification()`
  counts the de-duplicated set.
* `umg_check_scaling()` no longer accepts a constant parent as a
  scaling mark: a constant parent fixes the location of a latent
  variable, not its scale. `via` is now one of `"marker loading"`,
  `"fixed variance"`, `"marker weight"` (a unit-valued incoming weight
  from an observed cause, the marker convention for formative
  composites), or `"none"`, and a new informational column
  `location_fixed` reports whether a constant parent is present.
* `umg_formative()` now scales the composite: the weight of the first
  indicator is fixed to 1 (argument `scaling = "marker"`, the default;
  `"none"` reproduces the unscaled drawing), so the motif passes the
  package's own scaling check. The default motif with four causes and
  two outcomes counts 12 free parameters (previously 13) and df = 9.

## Converters and round trip

* `umg_from_lavaan()` (and `umg_from_blavaan()`) record the `~1` rows
  of the parameter table as mean annotations on the vertices
  (`mean = free`, `mean = 0`, `mean = <value>`, or `mean = fixed` for
  a mean fixed at a sample value under `fixed.x = TRUE`), and
  `umg_to_lavaan()` emits them as intercept lines (`v ~ 1`,
  `v ~ 0*1`, `v ~ <value>*1`). A growth model specified with
  `lavaan::growth()` now round-trips through `lavaan::cfa()` with
  identical npar, df, and chi-square (Demo.growth: 9, 5, 8.069);
  previously the `cfa()` refit silently dropped the mean structure
  (df = 3). Fits without a mean structure (the Holzinger-Swineford
  CFA) produce exactly the same syntax as before.
* Bayesian conversions append `prior` to an existing annotation
  instead of skipping vertices that already carried one.

## Export

* `umg_to_dot()` no longer writes `style=curved` on covariance edges,
  which Graphviz does not support (it warned "unsupported style curved"
  on every covariance edge and ignored it); the edges keep `dir=both`
  and `constraint=false`.
* `umg_to_dot()` emits the note "crossed plates rendered by
  smallest-enclosing assignment" only when plates actually cross, that
  is, when a vertex belongs to two plates neither of which encloses the
  other. Nested plates (a random-coefficient model from
  `umg_from_lmer()`) no longer trigger it.
* `umg_to_tikz()` never prints a negative zero coordinate (`-0`); a
  coordinate that rounds to zero from below is written as `0`.

## Package hygiene

* The `@importFrom` tags for grid and grDevices (one of which spanned
  several lines) imported symbols the code never uses unqualified;
  they are removed. Both packages remain in `Imports:` and are called
  with `::`.
* `inst/CITATION` cites the package as version 0.6.0 and adds the
  companion manuscript (Yu, H.-T., 2026, When is a diagram a model? A
  unified, determinate graphical notation for the statistical models
  of psychology; manuscript submitted for publication).

# umg 0.5.0

Correctness release prepared for the first CRAN submission. An
adversarial code review of 0.4.0 confirmed a set of defects that
`R CMD check` and the shape-level tests could not catch; all are fixed
here and each fix is pinned by a regression test
(`tests/testthat/test-regressions-050.R`).

## Statistical correctness of generated diagrams

* `umg_riclpm()` now encodes the Hamaker, Kuiper, and Grasman (2015)
  RI-CLPM exactly: wave-specific innovation covariances are drawn at
  every wave (not only wave 1), observed vertices carry `var = 0`
  because the within/between decomposition is exact, and the lagged
  paths are wave-indexed rather than sharing one label (which read as
  an unintended stationarity constraint). The counting rule now
  reproduces the textbook 27 free parameters / df = 9 for four waves.
* `umg_sem(scaling = "variance")` fixes the scale of *endogenous*
  factors too, by a unit residual-variance annotation matching
  lavaan's `std.lv = TRUE`; previously their scale was fixed by
  nothing.
* `umg_secondorder()` no longer fixes both the general factor's
  variance and its first loading (an over-restriction, not a scaling
  choice); the general factor is marker-scaled with a free variance.
* `umg_mixture()` keeps the mixing-proportion parameter outside the
  person plate (a population quantity), consistent with `umg_lca()`,
  and rejects unknown `plate` names with a clear error.
* `umg_dcm()` gains `attr_cov` (default `TRUE`) drawing the attribute
  associations that standard DCMs assume, warns when the Q-matrix
  looks transposed (items-by-attributes, the GDINA/CDM convention),
  and documents the attribute-level collapse.

## Identification tooling

* `umg_dsep()` is rewritten on the moralized ancestral graph criterion
  (Lauritzen et al., 1990). The previous implementation enumerated
  skeleton paths with a silent 20,000-path cap and returned wrong
  verdicts on moderately dense graphs (including a saturated 10-node
  network); the new test is exact and linear in the graph size.
* `umg_count_parameters()` subtracts any fixed variance read from a
  vertex's distribution annotation, whether the vertex is latent or
  observed and independently of marker scaling (previously a fixed
  variance was missed whenever a marker loading was also present, and
  observed fixed variances were always counted free). The counting
  rule now also declares itself inapplicable (`applicable = FALSE`,
  `df = NA`, with a warning) for models containing categorical random
  vertices, where the covariance-moment count is not a valid check.
* `umg_implied_ci(observed_only = TRUE)` now requires the conditioning
  set to be observed as well, so the listed statements are genuinely
  testable.

## Converter fidelity

* `umg_from_lavaan()` reads only the first group of a multi-group fit
  (with a message) instead of silently duplicating every edge once per
  group; types ordinal indicators as categorical and carries their
  threshold counts as annotations; falls back to the fitted value for
  parameters fixed with `NA` `ustart` (the `fixed.x = TRUE` case,
  which previously rendered a literal "NA"); and warns about, rather
  than crashing on, unsupported operators such as `<~`.
* `umg_from_mirt()` reads the item type from a fitted object instead
  of silently assuming `"2PL"`; an explicit `model` argument still
  overrides.
* `umg_from_qgraph()` symmetrises asymmetric (directed) weights
  matrices with a warning instead of silently dropping the lower
  triangle.
* `umg_from_lmer()`/`umg_from_brms()` warn when the grouping variable
  is missing from `data` instead of producing an "i = 1, ..., 0"
  plate.
* `umg_network()` accepts upper-, lower-, or fully symmetric adjacency
  matrices (previously a lower-triangular matrix yielded an empty
  graph).

## Rendering

* The ggplot2 backend now pulls edge endpoints back to the node
  boundary, so arrowheads are visible instead of hidden underneath the
  vertex glyphs; mixing edges get an open arrowhead (as in the grid
  and DOT backends); and deterministic vertices get an inner ring.
* `umg_to_tikz()` no longer corrupts coordinates at or above ~100 (the
  previous formatting capped output at four significant digits).
* Deterministic vertices are drawn with `peripheries=2` in DOT.
* Both renderers warn when an edge is skipped because its endpoints
  are closer than the node diameter (previously silent).
* An invalid `theme` argument is an error, and a style name
  (`"journal"`, `"slide"`, `"cb"`) is accepted anywhere a theme is;
  previously invalid themes were silently replaced by the default.
* `umg_save(..., backend = "ggplot")` writes SVG through `grDevices`
  so the svglite package is not required.
* Default labels no longer render stray backslashes (e.g. `\lambda`)
  in the grid, ggplot2, and DOT backends, and `umg_factor()`'s default
  factor label no longer emits an undefined TeX control sequence in
  TikZ export.

## Interface hardening

* `umg_edge()` validates `label` (character scalar; `NULL` is
  normalised to `""`) and `fixed` (non-missing scalar), closing a
  family of obscure downstream rendering errors.
* `umg_factor()` indexes user-supplied loading labels as documented
  (one label per free loading) and accepts a full-length vector for
  convenience.
* `umg_theme()` drops unknown elements after warning and rejects
  `NULL` element values.
* `umg_dsep()` rejects queries where `x`, `y`, or `given` overlap.

# umg 0.4.0

Hardening and round-trip release.

## New functionality

* `umg_to_lavaan()`: emit lavaan model syntax from a diagram, the
  inverse of `umg_from_lavaan()`. Directed edges from a latent to an
  observed vertex become measurement loadings (`=~`); other directed
  edges become regressions (`~`); covariance edges become `~~`. The
  convention is documented, and ambiguous or unrepresentable edges are
  flagged.
* `as.data.frame.umg()`: return the vertices or edges of a diagram as a
  tidy data frame for inspection, tabulation, and programmatic editing.
* `summary.umg()` / `print.summary.umg()`: a structured summary with
  vertex counts by type, edge counts by kind, the plate structure, and
  an identification snapshot.

## Bug fixes and hardening

* All `man/*.Rd` are now generated from the roxygen sources, fixing
  invalid single-backslash TeX escapes in several examples (e.g.
  `"$\eta_{1i}$"`) that previously caused a parse error under
  `R CMD check`.
* `print.umg` and `print.umg_identification` now document their
  arguments, and the `autoplot` method uses delayed S3 registration via
  `@exportS3Method`.
* `umg_growth()` validates that a supplied `times` vector matches the
  number of occasions instead of silently recycling or producing `NA`
  time scores.
* `umg_mixture()` reports an informative error when a target vertex is
  absent rather than failing later in validation.
* `umg_from_OpenMx()` ignores the diagonal of the RAM `A` matrix,
  avoiding a spurious self-loop (and the cycle error it would trigger).

# umg 0.3.0

Substantial expansion toward a CRAN-ready release.

## New model families (motif builders)

* `umg_sem()`: general SEM assembler from a measurement and structural
  specification, with marker or variance scaling.
* `umg_secondorder()`: hierarchical (second-order) factor model.
* `umg_esem()`: exploratory SEM with full cross-loadings.
* `umg_formative()`: formative (composite) measurement.
* `umg_mimic()`: multiple-indicator multiple-cause model.
* `umg_riclpm()`: random-intercept cross-lagged panel model.
* `umg_dcm()`: diagnostic classification model with a Q-matrix.
* `umg_irt()` now covers the polytomous `"graded"`, `"PCM"`, and
  `"GPCM"` families and multidimensional IRT via `n_dim`.

## New fitted-object converters

* `umg_from_blavaan()`: Bayesian SEM from blavaan.
* `umg_from_brms()`: Bayesian multilevel models from brms.
* `umg_from_OpenMx()`: RAM path models from OpenMx.
* `umg_from_qgraph()`: network models from a qgraph object or weights
  matrix.
* `umg_from_lavaan()` gains a `bayesian` argument.

## Identification tooling

* `umg_identify()` and its components `umg_check_scaling()`,
  `umg_count_parameters()`, `umg_labelswitching()`, `umg_dsep()`, and
  `umg_implied_ci()` read identification-relevant information off the
  diagram, including a d-separation reader that treats covariance edges
  as latent common causes.

## Rendering

* `umg_ggplot()` / `autoplot.umg()`: a ggplot2 backend.
* `umg_to_dot()` / `umg_render_dot()`: Graphviz DOT export and
  DiagrammeR rendering.
* `umg_save()` dispatches on `.dot`/`.gv` and accepts `backend =
  "ggplot"`.

## Exploratory duality

* `umg_eda_scaffold()` now also produces latent-score distributions,
  mixture densities, empirical response curves, and residual
  correlation heat maps.
* `umg_caterpillar()`: shrinkage/caterpillar plot for cluster
  estimates.

## Other

* `umg_node()` gains `fill` and `annot` arguments.
* New test suite covering constructors, the W1-W6 rules, all motifs,
  converters, layout, export backends, and identification tooling.

# umg 0.2.0

* Initial skeleton: constructors, validation (W1-W6), layered layout,
  grid renderer with themes, TikZ export, the original eight motif
  builders, the lavaan/lme4/mirt converters, and EDA duality scaffolds.
