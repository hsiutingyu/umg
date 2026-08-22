# Working Notes: umg Package, CRAN and R Journal Track (2608_CRAN_UMG)

**File:** WORKING_NOTES_CRAN_V01.md (append dated entries; never rewrite history)
**Guide:** CRAN_SUBMISSION_GUIDE_V01.md (the step-by-step procedure)
**Predecessor workspaces:** `_0_R_package/` (0.5.0, 2026-07-18), `CRAN_UMG/` (0.4.0), `Rpackage/` (0.2.0, the version the AMPPS reviewers saw); `manual/` (user manual V02 for 0.5.0)

---

## 2026-08-22: workspace created; 0.6.0 built

### Contents of this folder

| Item | Purpose |
|---|---|
| `umg/` | 0.6.0 working tree (the package to submit) |
| `umg_0.6.0.tar.gz` | built tarball, check-clean |
| `umg_src_0.5.0/` | untouched 0.5.0 reference (unpacked from `_0_R_package/umg_0.5.0.tar.gz`) |
| `CHANGES_060_V01.md` | every change 0.5.0 to 0.6.0, the test that pins it, and the demo re-run comparison |
| `check_umg_0.5.0.log`, `check_umg_0.6.0.log` | `R CMD check --as-cran --no-manual` logs (sandbox, R 4.3.3) |
| `package_issues_V01.txt`, `package_issues_V01.R` | the 14 behaviours found in 0.5.0 during the manuscript demonstrations, with reproduction code |
| `demo_rerun_060/` | the eight manuscript demonstration scripts re-run against 0.6.0 (numbers reproduced) |
| `REVIEW_v0.5.0.md`, `GUIDELINES_next_steps_V01_from_0_R_package.md`, `cran-comments_0.5.0.md`, `DESCRIPTION_0.5.0.txt`, `CITATION_0.5.0.txt` | carried over from `_0_R_package/` for reference |

### Why 0.6.0 exists

The manuscript demonstrations exercised the package harder than the 0.5.0 review did and found fourteen behaviours worth recording (`package_issues_V01.txt`). Nine were fixed today because they affect correctness or the claims a reader would make from the package's output: the W5 plate rules were incomplete (a child-plate vertex could be missing from its parent; an item parameter could be drawn as a parent of a person ability; a mixing edge was unconstrained); the counting rule with `meanstructure = TRUE` counted one mean per random vertex and returned df = 1 for a growth model whose df is 5; `umg_implied_ci()` listed every symmetric statement twice; a constant parent was accepted as fixing a latent variable's scale (it fixes location); `umg_formative()` failed its own scaling check; DOT export emitted `style=curved` (rejected by Graphviz) and a misleading crossed-plates note for nested plates; TikZ export printed `-0`; the lavaan converters dropped the mean structure; and two roxygen `@importFrom` tags were malformed or unused (the AMPPS reviewer's R1-P4). Five were deferred as rendering or design items (annotations not printed by the automatic renderers; arrowheads hidden under square vertices and other layout collisions; MIMIC and formative motifs and the treatment of conditioned observed causes; the counting rule's blindness to rotational constraints in ESEM; the slope-factor "score" in the exploratory scaffold being a row mean). All are listed in the manuscript's Discussion as 0.5.0 limitations, and the manuscript states that the next release addresses the first group.

### Verification

- `devtools::document()` clean; `devtools::test()`: 10 files, 87 tests, 313 assertions, 0 failures (0.5.0: 74 tests, 212 assertions). New `tests/testthat/test-regressions-060.R` pins every fix to its reproduction.
- `R CMD check --as-cran --no-manual`: 0 errors, 0 warnings, 2 NOTEs (new submission with the GitHub URL not yet live; sandbox timestamp). Run with `LANG=C.UTF-8`; with the sandbox's unset locale an environmental locale warning appears that cannot occur on CRAN.
- No motif builder and no converter needed correction under the new W5 rules: all 25 builder variants and the lavaan, lmer, mirt, brms, and qgraph converter examples validate unchanged.
- Demo re-run: every number in the manuscript is reproduced under 0.6.0 (Holzinger and Swineford round trip 21/24/85.306, max difference 2.2e-16, byte-identical emitted syntax; counting 45/21/24; RI-CLPM 36/27/9; d-separation verdicts agree with dagitty; diff 24 to 23 df). Differences are exactly the fixes: the three plate-rule cases now refused; the growth model now round-trips through `cfa()` with identical df (9/5); meanstructure count 9/df 5; implied-CI counts halved where duplicated; constant-parent case reported as unscaled; formative motif now scaled (df 9). The gallery script's hard-coded hand check for the formative motif now prints MISMATCH because the expected value was the 0.5.0 behaviour; update that expectation when the gallery is regenerated for the deposit.

### Decisions needed from HT

1. **Release sequence** (guide, Phase 0): 0.6.0 as the first CRAN version (recommended) or 0.5.0 first.
2. **Manuscript version**: after the decision, V02 of the manuscript switches `\pkgversion` to 0.6.0, simplifies the package paragraph ("refuses violations of W1, W3 (first clause), W4, and all four clauses of W5; warns on W2; supplies the W6 defaults"), removes the four fixed items from the Discussion limitation paragraph, updates the bib entry, and regenerates the gallery table; the benchmark reference row is unchanged (F8 and F10 remain Partial; O1 to O10 unchanged).
3. **Terminology alignment** (guide, Phase 3): after HT approves the manuscript wording; documentation only; no function renames.
4. **`umg_diff()`**: add as a convenience in 0.6.1 or 0.7.0 so the manuscript's sixth operation has a named function (the manuscript currently uses `as.data.frame()` and `setdiff()`, which is fine).
5. **GitHub account and repository name**: DESCRIPTION assumes `hsiutingyu/umg`; change both URL fields if a different organization or name is used.

### What HT must do personally (accounts and machine)

Guide steps 1.1 (GitHub), 1.2 (local check on current R), 1.3 (win-builder and macOS builder), 2.1 and 2.2 (CRAN upload and confirmation e-mail), 4.3 (R Journal form). Everything else can be done in a session.

### Risks

- CRAN's human review of a first submission often asks for small Description or Rd changes; budget one resubmission (0.6.1).
- CRAN latency (days to two weeks) means the package may not be live by 2026-08-31; the manuscript cites the version and the GitHub release, and the author note says the archived version is recorded in the deposit. If CRAN acceptance arrives during review, the copyeditor can update the citation.
- The sandbox runs R 4.3.3; CRAN checks on R-devel and R-release. Step 1.2 on a current R is not optional.
- Reverse-dependency-free and base-R-only imports keep the maintenance burden low; the only scheduled migration is `lme4::findbars()` to `reformulas`.
