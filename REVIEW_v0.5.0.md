# umg package review and revision: 0.4.0 -> 0.5.0

Date: 2026-07-18. Prepared for H.-T. Yu.

This round subjected 0.4.0 to an adversarial two-track code review
(rendering/export track and statistical/graph-algorithm track), with
every candidate finding verified by execution before being accepted.
The review confirmed that 0.4.0, although clean under
`R CMD check --as-cran` and its own test suite, produced *silently
wrong output* in several places that shape-level tests cannot catch.
All confirmed defects are fixed in 0.5.0 and pinned by regression
tests. This is the version prepared for the first CRAN submission.

## Verification status of 0.5.0

* `R CMD check --as-cran` on `umg_0.5.0.tar.gz`: 0 ERRORs,
  0 WARNINGs, 3 NOTEs, all expected and environmental:
  (1) "New submission" plus the GitHub URL (repository not yet
  created; step 1 of the guidelines), (2) blavaan/brms/OpenMx not
  installed locally (checked with `_R_CHECK_FORCE_SUGGESTS_=false`),
  (3) "unable to verify current time" (sandbox clock, does not occur
  on CRAN machines).
* testthat: 9 files, 74 tests, 212 passing assertions, 0 failures,
  0 skips (lavaan, lme4, mirt, qgraph, ggplot2, DiagrammeR all
  installed and exercised).
* Vignettes rebuild; PDF reference manual compiles.

## Confirmed defects fixed (severity: statistically wrong output)

1. `umg_dsep()` used exhaustive skeleton-path enumeration with a
   silent 20,000-path cap; on a saturated 10-node network it returned
   TRUE for two *directly connected* vertices, poisoning
   `umg_implied_ci()` and `umg_identify()`. Rewritten on the
   moralized ancestral graph criterion (Lauritzen, Dawid, Larsen, &
   Leimer, 1990): exact, linear time.
2. `umg_from_lavaan()` drew every edge once per group for multi-group
   fits (24 instead of 12 edges for a two-group Holzinger-Swineford
   CFA). Now reads the first group's structure with a message.
3. `umg_riclpm()` omitted the wave-specific innovation covariances,
   left free residual variances on the observed vertices (the
   decomposition is exact; they are 0), and reused one label across
   all lagged transitions (reading as an unintended stationarity
   constraint). The 4-wave motif now counts 27 free parameters,
   df = 9, matching Hamaker, Kuiper, and Grasman (2015).
4. `umg_count_parameters()` (a) never subtracted fixed variances on
   observed vertices, (b) missed a latent fixed variance whenever a
   marker loading was also present, and (c) applied the
   covariance-moment count to categorical models (reporting an
   identified 2PL as "under-identified"). Fixed-variance detection is
   now annotation-based and role-independent; categorical models are
   flagged `applicable = FALSE` with `df = NA` and a warning.
5. `umg_sem(scaling = "variance")` left endogenous factors with no
   scaling constraint at all; they now carry `resid var = 1`
   (lavaan `std.lv = TRUE` convention).
6. `umg_secondorder()` fixed both the general factor variance and its
   first loading (over-restriction); now marker scaling only.
7. `umg_mixture()` placed the mixing-proportion parameter inside the
   person plate (person-indexed mixing proportions); now outside,
   consistent with `umg_lca()`.
8. `umg_from_mirt()` ignored the fitted item type and always drew a
   2PL; now read from the object (Rasch -> 1PL; graded/grsm/gpcm ->
   graded), overridable by an explicit `model`.
9. `umg_from_qgraph()` silently discarded the lower triangle of
   asymmetric (directed) weights matrices; now symmetrises with a
   warning. `umg_network()` likewise ignored lower-triangular
   adjacency input, yielding an empty graph; both triangles are now
   read.

## Confirmed defects fixed (severity: rendering/interface)

10. ggplot2 backend: arrowheads were drawn at vertex centres and then
    hidden underneath the vertex glyphs, so directed graphs rendered
    as undirected lines; endpoints are now shrunk to the node
    boundary. Mixing edges now carry an open arrowhead and
    deterministic vertices an inner ring (parity with grid/DOT).
11. `umg_to_tikz()` silently corrupted coordinates >= ~100
    (`formatC(format = "fg")` with no digits caps at 4 significant
    digits); exact fixed-notation formatting now.
12. `umg_edge(label = NULL)` crashed all four backends with obscure
    errors; the constructor now validates `label` and `fixed`.
13. Invalid `theme` arguments were silently replaced by the default
    theme; now an error, and style names ("journal", "slide", "cb")
    are accepted anywhere a theme is.
14. Edges skipped because endpoints were closer than the node
    diameter vanished silently; both renderers now warn.
15. Default labels rendered stray backslashes (e.g. `\lambda`, and
    `umg_factor()`'s default TikZ label `\F` was an undefined control
    sequence); display stripping and the default label are fixed.
16. `umg_save(..., backend = "ggplot")` to `.svg` required the
    undeclared svglite package; SVG is now written through grDevices.
17. `umg_theme()` inserted unknown elements after warning and
    accepted NULL values that crashed `plot.umg()` later; unknown
    elements are dropped and NULLs rejected.
18. CRAN polish: `\dontrun` replaced by `@examplesIf` for
    ggplot2/DiagrammeR examples; `umg_save()` examples write to
    `tempfile()`; `Language: en-US` added; stray `synctest` file
    removed; `inst/CITATION` added.

## Smaller fixes

* `umg_factor()` loadings-label indexing now matches its
  documentation (one label per free loading; full-length vectors
  accepted).
* `umg_implied_ci(observed_only = TRUE)` requires observed
  conditioning sets (testability).
* `umg_from_lavaan()`: ordinal indicators typed categorical with
  threshold-count annotations; `fixed.x = TRUE` moments no longer
  render "NA"; unsupported operators (e.g. `<~`) warn instead of
  crashing.
* `umg_from_lmer()`/`umg_from_brms()` warn when the grouping column
  is absent from `data`.
* `umg_dcm()`: transposed-Q warning, documented attribute-level
  collapse, and `attr_cov = TRUE` drawing standard attribute
  associations.
* `umg_dsep()` rejects degenerate queries (x = y or overlap with the
  conditioning set).
* DOT: deterministic vertices get `peripheries=2`.

## Remaining maintainer actions (unchanged from 0.4.0 where noted)

* Create the public GitHub repository so URL/BugReports resolve
  (guidelines step 1).
* Run win-builder and R-hub before submission (guidelines step 4).
* Add the published article reference (with DOI) to DESCRIPTION and
  inst/CITATION when available.
* `umg_from_lmer()` still relies on `lme4::findbars()`/`nobars()`;
  recent lme4 points to the `reformulas` package. Functional today;
  track for a future release.
