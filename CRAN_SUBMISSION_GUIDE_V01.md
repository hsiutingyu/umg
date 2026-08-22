# umg: Step-by-Step Guide to CRAN Submission and the R Journal (V01)

**File:** CRAN_SUBMISSION_GUIDE_V01.md
**Workspace:** `GraphicalPresentation/2608_CRAN_UMG/`
**Date:** 2026-08-22
**State when written:** `umg/` holds version **0.6.0** (correctness release built today from 0.5.0; `R CMD check --as-cran`: 0 errors, 0 warnings, 2 expected notes; testthat 87 tests, 313 assertions, 0 failures). `umg_0.6.0.tar.gz` is the built tarball. `umg_src_0.5.0/` is the untouched reference. `CHANGES_060_V01.md` documents every change.
**Steps marked [YOU] need your accounts or your machine; steps marked [CLAUDE] can be done in a session; steps marked [BOTH] need both.**

---

## Phase 0. Decide the release sequence (one decision, today)

The manuscript `2608_PEM/manuscript/PM_UMG_V01.tex` cites version 0.5.0 and describes its limitations candidly; version 0.6.0 removes four of them (W5 plate checks, mean structure through the lavaan converters, the scaling rule, duplicated independence statements) and reproduces every number in the manuscript (`demo_rerun_060/`). Two options:

- **Option R1 (recommended): release 0.6.0 as the first CRAN version**, then update the manuscript to 0.6.0 in V02 (see `2608_PEM/notes/WORKING_NOTES_PEM_V01.md`, open item 2). One package version in the paper, on CRAN, and in the OSF deposit.
- Option R2: release 0.5.0 now and 0.6.0 later. Faster by a day but leaves the paper describing limitations the released package has already fixed, and CRAN dislikes rapid re-submissions (they ask for at least one to two months between versions unless fixing a check failure).

Terminology alignment with the manuscript (Phase 3) changes documentation text only; it can be done before or after the first CRAN release. If the paper is submitted first, align the wording at the 0.6.x patch that adds the published reference.

---

## Phase 1. Pre-submission checks (1 day)

### 1.1 Public GitHub repository [YOU]
DESCRIPTION points to `https://github.com/hsiutingyu/umg` and `.../issues`; the only substantive CRAN NOTE is that these URLs return 403 because the repository does not exist.

1. Log in to GitHub as `hsiutingyu`; create a new **public** repository named exactly `umg`; do not initialize it with a README.
2. On your machine, from `2608_CRAN_UMG/`:
   ```bash
   cd umg
   git init
   git add .
   git commit -m "umg 0.6.0: CRAN submission candidate"
   git branch -M main
   git remote add origin https://github.com/hsiutingyu/umg.git
   git push -u origin main
   git tag v0.6.0 && git push --tags
   ```
3. Settings: confirm Issues are enabled.

### 1.2 Local check on your own machine [YOU]
CRAN expects a check on current R (4.5.x at the time of writing; the sandbox runs 4.3.3). In R, from `2608_CRAN_UMG/`:
```r
install.packages(c("devtools", "roxygen2", "testthat", "lavaan", "lme4", "mirt", "qgraph", "ggplot2", "DiagrammeR", "knitr", "rmarkdown"))
devtools::document("umg")      # should be a no-op
devtools::test("umg")          # expect 87 tests, 313 assertions, 0 failures
devtools::check("umg", args = "--as-cran")
```
Acceptable NOTEs: "New submission" only (the URL NOTE disappears once 1.1 is done). Fix anything else before continuing. If `blavaan`, `brms`, or `OpenMx` are not installed, the corresponding tests and examples skip cleanly; a NOTE about unavailable suggested packages is acceptable only if `_R_CHECK_FORCE_SUGGESTS_=false` is set, so install them if you can.

### 1.3 Cross-platform checks [YOU, about an hour of waiting]
```r
devtools::check_win_devel("umg")     # R-devel on Windows (results by e-mail)
devtools::check_win_release("umg")   # R-release on Windows
devtools::check_mac_release("umg")   # macOS builder
```
Optional: `rhub::rhub_check()` (R-hub v2 needs the GitHub repository; choose the `linux`, `windows`, and `macos` platforms). Keep the result e-mails; they go into cran-comments.

### 1.4 Final metadata pass [CLAUDE, after 1.1 to 1.3 results are known]
- `cran-comments.md`: replace the 0.5.0 text (`cran-comments_0.5.0.md` in this folder) with the real test environments and results from 1.2 and 1.3; mention the single expected NOTE.
- `DESCRIPTION`: confirm `Date` (add `Date: YYYY-MM-DD` if desired), `Authors@R`, `URL`, `BugReports`; keep `Language: en-US`.
- Spell-check: `devtools::spell_check("umg")` (add legitimate words to `inst/WORDLIST`).
- Confirm every example that writes files uses `tempfile()`/`tempdir()` (already the case in 0.5.0; re-check for new code).
- Rebuild the tarball: `devtools::build("umg")`.

---

## Phase 2. Submit to CRAN (30 minutes plus waiting)

1. [YOU] Go to https://cran.r-project.org/submit.html. Upload `umg_0.6.0.tar.gz`, enter name and e-mail (`hsiutingyu@gmail.com`, the maintainer address in DESCRIPTION), paste the contents of `cran-comments.md` into the optional comments box, submit.
2. [YOU] Confirm the submission by clicking the link in the e-mail CRAN sends to the maintainer address (the submission is discarded without this step).
3. Automated incoming checks run within an hour; a CRAN team member then reviews new submissions by hand, typically within one to ten days. Three outcomes:
   - **Accepted**: a "package umg_0.6.0.tar.gz is on its way to CRAN" e-mail; binaries appear over the following days.
   - **Needs fixing** (common for first submissions: Description wording, a missing `\value` section in an Rd file, a URL, an example running too long): fix, bump to 0.6.1, rebuild, resubmit with a cran-comments line that says what changed in response.
   - **Rejected** on policy grounds: read the CRAN policy text quoted in the e-mail; it is always specific.
4. [BOTH] After acceptance: tag the release on GitHub; add the CRAN badge to README; build the pkgdown site (`usethis::use_pkgdown()`, `pkgdown::build_site()`, GitHub Pages); optionally mint a Zenodo DOI for the release.

Common first-submission pitfalls already handled in 0.6.0: Imports restricted to base packages; every suggested package guarded; examples write only to temp; tests skip when a suggested package is absent; Title in title case; Description does not start with the package name; no `\dontrun{}` where `\donttest{}` would do.

---

## Phase 3. Terminology alignment with the manuscript (after HT approves the manuscript text) [CLAUDE]

The manuscript fixes the vocabulary; the package should use the same words in the same order. The alignment pass touches documentation only (Rd titles and descriptions, README, vignettes, DESCRIPTION Description field, the NEWS entry), never function names or arguments, so it is safe after CRAN acceptance and belongs in the 0.6.x patch that adds the published reference.

| Manuscript term (order of introduction) | Package wording to use | Where |
|---|---|---|
| Unified Model Graph (UMG); "a notation with a semantics" (not "visualization grammar") | Keep "Unified Model Graph"; replace "formal graphical grammar" in DESCRIPTION with "a formal graphical notation with a semantics" | DESCRIPTION, README, umg-package.Rd |
| Three typing questions, in this order: observability (measured or inferred), support (continuous or categorical), inferential role (random variable, parameter, deterministic, constant) | `umg_node()` documentation lists arguments and their values in this order | umg_node.Rd, umg-intro vignette |
| Edge kinds, in this order: stochastic dependence (dep), covariance (cov), deterministic (det), mixing (mix) | `umg_edge()` documentation; NEWS | umg_edge.Rd |
| Plates (nested, crossed); badge (statistical, structural) | `umg_plate()`, `umg_model(badge=)` docs | umg_plate.Rd, umg_model.Rd |
| Well-formedness W1 to W6 with the 0.6.0 clauses (W5a nesting, W5b membership, W5c licensing, W5d mixing) | `umg_validate()` documentation and error messages already match; add the W-labels to the vignette | umg_validate.Rd, umg-intro vignette |
| The six operations, in the manuscript's order: validation, translation (round trip), identification reading, implied independencies and d-separation, model-implied displays, differencing | Reorder the README "Reading a diagram" block and the identification vignette to this order; add a short `umg_diff()` convenience (edges and vertices set difference) so the sixth operation has a function | README, umg-identification vignette, new R/diff.R |
| Determinacy, coverage, conservativity (criteria C1 to C3) | One paragraph in umg-package.Rd pointing to the manuscript | umg-package.Rd |
| Reserved versus free channels (Table 4 of the manuscript) | `umg_theme()` documentation: reserved channels cannot be overridden; free channels (hue, size, stroke) are what themes change | umg_theme.Rd |

Deliverables of this phase: 0.6.1 (or 0.7.0 if `umg_diff()` is added) with `inst/CITATION` pointing to the manuscript's published reference once available, NEWS entry, re-run of the test suite and `R CMD check`.

---

## Phase 4. The R Journal note (after CRAN acceptance)

Requirements verified on journal.r-project.org/submissions (2026-08-22): articles "should be no more than 20 pages"; submit through the journal's Google Form a zip (maximum 10 MB) with the PDF, the source (`.Rmd` via rjtools, or `.tex` from the template), the `.bib` containing only cited references with package names in braces, the reproducible R scripts and data, a cover letter, and `_Rpackages.txt`; `rjtools::initial_check_article()` must pass (title case, sentence-case headings, spelling, package available on CRAN); the package must be on CRAN or Bioconductor before submission; the article must not be under consideration elsewhere.

Steps:
1. [CLAUDE] Update `_0_R_package/paper_rjournal/yu-umg.Rmd` to 0.6.x: re-run every chunk, align terminology (Phase 3), cite the Psychological Methods manuscript as submitted or in press, and cite the package version on CRAN. Keep to the 11-page length; the 20-page limit leaves room for one figure showing the six operations.
2. [CLAUDE] `rjtools::initial_check_article()`; ignore only the two known false positives (lower-case package name in the title; "Unified Model Graph" as a proper noun).
3. [YOU] Complete the Google Form; upload the zip; keep the confirmation.
4. Review takes several months; revisions carry a three-month deadline.

Do not submit the R Journal note before CRAN acceptance (their initial check requires the CRAN package) and do not let it share text with the Psychological Methods manuscript (the note describes the interface; the manuscript proves the notation).

---

## Phase 5. Maintenance after the first release

- Respond to CRAN e-mails about reverse dependencies or new check failures within the stated deadline (usually two weeks).
- `lme4` has deprecated `findbars()` in favor of `reformulas`; migrate when the deprecation warning appears in checks.
- When the manuscript is accepted, release a patch that adds the published reference and DOI to `inst/CITATION` and DESCRIPTION (Crossref-verified only).
- Keep `NEWS.md` as the changelog; bump the version for every CRAN submission (CRAN rejects a resubmission with an unchanged version number).

---

## Checklist (tick in the working notes)

- [ ] Phase 0 decision recorded
- [ ] 1.1 repository live; URL NOTE gone
- [ ] 1.2 local check clean on current R
- [ ] 1.3 win-builder devel and release, macOS builder clean
- [ ] 1.4 cran-comments written from real results; spell check; tarball rebuilt
- [ ] 2.1 submitted; 2.2 confirmation link clicked
- [ ] 2.3 outcome recorded; fixes if requested
- [ ] 2.4 tag, badge, pkgdown
- [ ] Phase 3 terminology pass (after manuscript approval)
- [ ] Phase 4 R Journal zip and form (after CRAN acceptance)
