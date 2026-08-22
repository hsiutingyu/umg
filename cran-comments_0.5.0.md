# cran-comments for umg 0.5.0

## Submission notes

This is the first CRAN submission of umg (version 0.5.0).

## Test environments

* Local: R 4.3.3 on Ubuntu 24.04 (x86_64). `R CMD check --as-cran` on
  the built tarball: 0 ERRORs, 0 WARNINGs.
* Suggested packages exercised locally: lavaan, lme4, mirt, qgraph,
  ggplot2, DiagrammeR, knitr, rmarkdown, testthat. blavaan, brms, and
  OpenMx paths are guarded by requireNamespace()/skip_if_not_installed()
  and were checked with `_R_CHECK_FORCE_SUGGESTS_=false`.
* Before submission, also run: win-builder (devel and release) and
  R-hub v2 (Windows, macOS, Linux) — see the step-by-step guidelines
  in the repository.

## R CMD check results

0 ERRORs, 0 WARNINGs.

Expected NOTEs:

* "New submission" (first submission).
* "Possibly invalid URL" for https://github.com/hsiutingyu/umg until
  the public repository is created; the repository will be live before
  submission.

## Tests

* testthat suite: 200+ assertions across 9 files, including a
  dedicated regression file (test-regressions-050.R) that pins every
  defect fixed in the 0.4.0 -> 0.5.0 review (d-separation exactness,
  counting-rule edge cases, motif correctness for the RI-CLPM,
  variance-scaled SEM and second-order models, converter fidelity for
  multi-group lavaan, mirt item types, and asymmetric network
  matrices, and rendering regressions).
* Tests requiring a suggested package are skipped cleanly when the
  package is absent.

## Dependencies

* Imports are restricted to base packages (grid, grDevices, stats,
  tools, utils).
* All modelling and rendering integrations are in Suggests; every
  function that uses a suggested package guards it with
  requireNamespace() and fails with an informative message.
* Examples that need a suggested package use @examplesIf; examples
  that write files write to tempfile()/tempdir() only.

## Reverse dependencies

None (first submission).
