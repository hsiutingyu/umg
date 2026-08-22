# umg: Step-by-Step Guidelines from Here to CRAN and the R Journal

File:   GUIDELINES_next_steps_V01.md
Author: prepared for H.-T. Yu
Date:   2026-07-18
Scope:  everything that remains between the current state (umg 0.5.0,
        check-clean, in `_0_R_package/`) and (a) a published CRAN
        package, (b) an R Journal article, (c) a possible later JSS
        paper. Steps you must do yourself (accounts, uploads, emails)
        are marked **[YOU]**; steps I can do in a future session are
        marked **[CLAUDE]**.

--------------------------------------------------------------------
## Current state (verified 2026-07-18)

* `_0_R_package/umg/` — package source, version 0.5.0.
* `_0_R_package/umg_0.5.0.tar.gz` — built tarball.
* `R CMD check --as-cran`: 0 ERRORs, 0 WARNINGs, 3 NOTEs, all
  expected: "New submission" + the not-yet-created GitHub URL;
  blavaan/brms/OpenMx absent locally; sandbox clock. See
  `REVIEW_v0.5.0.md` for the full revision report.
* testthat: 9 files, 74 tests, 212 assertions, 0 failures.
* `_0_R_package/manual/umg-manual_V02.{Rmd,pdf,html}` — user manual.
* `_0_R_package/paper_rjournal/` — R Journal draft (renders to an
  11-page PDF; limit is 20), cover letter, subset bibliography.

--------------------------------------------------------------------
## Phase A — Publish the package on CRAN

### Step A1. Create the public GitHub repository  **[YOU]**

The DESCRIPTION already points to `https://github.com/hsiutingyu/umg`.

1. Log in to GitHub as `hsiutingyu`; create a new **public** repository
   named exactly `umg`. Do not initialize it with a README (the
   package has one).
2. On your machine, from the folder that contains the package source:

   ```bash
   cd _0_R_package/umg
   git init
   git add .
   git commit -m "umg 0.5.0: CRAN submission candidate"
   git branch -M main
   git remote add origin https://github.com/hsiutingyu/umg.git
   git push -u origin main
   ```

3. In the repository Settings, confirm Issues are enabled (BugReports
   points at `/issues`).

This single step clears the only substantive CRAN NOTE.

### Step A2. Final local verification on your own machine  **[YOU]**

CRAN expects checks on current R. In R (>= 4.4 recommended), from the
directory containing `umg/`:

```r
install.packages(c("devtools", "roxygen2", "testthat"))
devtools::document("umg")     # regenerate man/ + NAMESPACE (should be a no-op)
devtools::test("umg")         # expect 212 passing assertions
devtools::check("umg", args = "--as-cran")
```

Accept only: the New-submission NOTE. Any new NOTE from your platform
(e.g., missing TeX fonts) should be resolved or understood before
proceeding. If lavaan/lme4/mirt/qgraph/ggplot2 are not installed
locally, install them so the full suite runs rather than skipping.

### Step A3. Cross-platform checks  **[YOU, ~1 hour of waiting]**

CRAN effectively expects evidence from Windows and the development
version of R:

1. **win-builder** (no account needed):

   ```r
   devtools::check_win_devel("umg")    # R-devel on Windows
   devtools::check_win_release("umg")  # R-release on Windows
   ```

   Results arrive by email to the maintainer address
   (hsiutingyu@gmail.com) within ~30-60 minutes.

2. **macOS builder** (no account needed): upload the tarball at
   https://mac.r-project.org/macbuilder/submit.html

3. **R-hub v2** (optional but useful; runs as GitHub Actions in the
   repository created in A1):

   ```r
   install.packages("rhub")
   rhub::rhub_setup()      # commits a workflow file; push it
   rhub::rhub_check()      # pick linux, windows, macos
   ```

4. Record the outcomes in `umg/cran-comments.md` (replace the
   "Before submission, also run" paragraph with the actual results).
   **[CLAUDE can update the file if you paste the results.]**

### Step A4. Pre-submission checklist  **[YOU / CLAUDE]**

- [ ] GitHub repository live; URL and BugReports resolve.
- [ ] `devtools::check(args = "--as-cran")` clean on your machine.
- [ ] win-builder devel + release: no ERROR/WARNING; only the
      New-submission NOTE.
- [ ] Version is 0.5.0 in DESCRIPTION and NEWS.md heading matches.
- [ ] cran-comments.md updated with real check results.
- [ ] Maintainer email is one you will answer promptly for the next
      few weeks (CRAN corresponds by email and expects replies).

### Step A5. Submit to CRAN  **[YOU, 10 minutes]**

1. Rebuild the tarball with current R so timestamps are fresh:

   ```r
   devtools::build("umg")   # produces umg_0.5.0.tar.gz
   ```

2. Go to https://cran.r-project.org/submit.html
3. Fill in name (Hsiu-Ting Yu), email (the maintainer address), upload
   `umg_0.5.0.tar.gz`, and paste the content of `cran-comments.md`
   into the optional comment field.
4. You will receive a **confirmation email**; you must click the
   confirmation link for the submission to enter the queue.

### Step A6. The CRAN review loop  **[YOU]**

What to expect, in order:

1. Automated incoming checks run within hours; results are emailed.
   A "pretest" failure returns the package to you without human
   review — fix and resubmit.
2. A CRAN volunteer reviews new submissions manually (typically days
   to ~2 weeks). First submissions commonly receive small requests:
   quoting package names in DESCRIPTION, a reference in the
   Description field, examples that run faster, etc.
3. When responding: fix everything requested, keep the version at
   0.5.0 unless code changed (then 0.5.1), update cran-comments.md
   with a "Resubmission" section listing each request and what you
   did, and submit again through the same form. Never argue in the
   form comment; if a request seems mistaken, explain briefly and
   politely.  **[CLAUDE can prepare each resubmission.]**
4. On acceptance you receive "on its way to CRAN"; binaries appear
   over the following days.

### Step A7. Immediately after acceptance  **[YOU / CLAUDE]**

- [ ] Tag the release: `git tag v0.5.0 && git push --tags`.
- [ ] Add a CRAN badge and `install.packages("umg")` to README.md.
- [ ] Build the pkgdown site (config `_pkgdown.yml` already exists):

  ```r
  install.packages("pkgdown")
  usethis::use_pkgdown_github_pages()   # sets up gh-pages via Actions
  ```

- [ ] Start `0.5.0.9000` development version in DESCRIPTION on main.

--------------------------------------------------------------------
## Phase B — Submit the article to the R Journal

Do this **after** CRAN acceptance: the R Journal's checks
(`check_proposed_pkg()`) look for the package on CRAN, and reviewers
install it from there.

### Step B1. Finalize the draft  **[YOU review / CLAUDE revise]**

The draft is `_0_R_package/paper_rjournal/yu-umg.Rmd`. It renders to
11 pages (limit 20) with all code executed. Before submission:

- [ ] Read the draft critically; revise voice and emphasis where you
      want (it is written software-first, as the venue expects; the
      theoretical argument is deliberately compressed into two
      sections with the companion article carrying the theory).
- [ ] Decide how to phrase the companion-article status in the cover
      letter and Summary (currently "under separate review").
- [ ] Set `draft: false` in the YAML header.
- [ ] Re-render: `rmarkdown::render("yu-umg.Rmd")` (produces PDF and
      HTML; both are required).
- [ ] Run the checks: `rjtools::initial_check_article(".")`.
      Two flagged items are known false positives you may ignore:
      the title-case check objects to the lowercase package name
      (R Journal titles keep package names lowercase), and the
      sentence-case check objects to "Unified Model Graph" (a proper
      noun).

### Step B2. Assemble the submission zip  **[YOU / CLAUDE]**

One zip, under 10 MB, containing:

- `yu-umg.Rmd`, `yu-umg.pdf`, `yu-umg.html`, `RJreferences.bib`,
  `RJournal.sty`, the `figures/` folder
- `motivation-letter/motivation-letter.md` rendered to PDF (the cover
  letter is already drafted)
- `_Rpackages.txt` — a plain list of the packages needed to compile
  the article (umg, lavaan, lme4, ggplot2, knitr, rmarkdown, rjtools)
- No `.log`/`.aux`/`.out` files.

### Step B3. Submit  **[YOU]**

Complete the submission form linked from
https://journal.r-project.org/submissions.html and upload the zip.
Note the submission identifier you receive; all revisions quote it.

### Step B4. Review expectations  **[YOU]**

The editors first check technical compliance, then topical fit, then
send the article to reviewers; the R Journal states this can take
several months. Verdicts are Accept / Minor (3-month deadline) /
Major / Reject. Keep the package version in the article current if
you release updates during review.

--------------------------------------------------------------------
## Phase C — JSS later?

A candid note so the strategy is explicit. JSS and the R Journal do
not publish the same software paper twice; "R Journal first, JSS
later" therefore means one of:

1. **R Journal now** for the package paper (recommended: faster,
   ideal fit for a package presentation), and JSS only if a future,
   substantially extended piece of software work justifies a new
   paper (e.g., a umg 2.0 with the plate calculus extended to random
   index sets, or the perceptual validation study wrapped in
   software); or
2. **JSS instead**, if you prefer its longer format and citation
   profile: withdraw from the R Journal plan, reformat with the
   `jss` article class (`rticles::jss_article`), expand the
   methodological sections (the compressed grammar section would
   grow back toward the manuscript), and expect a review cycle of a
   year or more.

The prepared draft converts to the JSS format with modest effort
(same code chunks; different wrapper and length norms).
**[CLAUDE can do the conversion if you choose 2.]**

Note also that the *theoretical* manuscript
(`paper/main_UMG_V02.tex`, targeted at Psychological Review) is a
separate publication track and is unaffected: software venue papers
and the theory paper cite each other.

--------------------------------------------------------------------
## Phase D — Ongoing maintenance

* **lme4 dependency drift.** `umg_from_lmer()` uses
  `lme4::findbars()`/`nobars()`; recent lme4 points at the
  `reformulas` package. Works today; migrate when lme4 deprecates
  formally (a NOTE will appear in CRAN checks — that is the trigger).
* **Published reference.** When the theory article (or the R Journal
  article) is accepted, add it to the DESCRIPTION `Description:`
  field (CRAN's preferred `Authors (Year) <doi:...>` form) and to
  `inst/CITATION`, and release as 0.6.0.
* **Version policy.** Reserve 1.0.0 for the release that accompanies
  the published companion article.
* **DOI discipline** (per your standing rules): every DOI added to
  DESCRIPTION, CITATION, or the article bibliography must be
  Crossref-verified before it goes in.

--------------------------------------------------------------------
## One-page summary of the critical path

1. Create github.com/hsiutingyu/umg and push the package  → clears
   the last real NOTE.
2. `devtools::check(args = "--as-cran")` locally, then win-builder
   (devel + release) and macOS builder.
3. Update cran-comments.md with the results.
4. Rebuild tarball; submit at cran.r-project.org/submit.html; click
   the confirmation email; answer CRAN promptly.
5. After acceptance: tag, badge, pkgdown, dev version.
6. Finalize yu-umg.Rmd (draft: false), render, rjtools checks, zip
   with _Rpackages.txt and cover letter, submit via the R Journal
   form.
7. JSS remains available later for a substantially extended paper;
   the Psychological Review manuscript proceeds independently.
