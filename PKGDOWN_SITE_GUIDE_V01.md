# umg documentation site: publish and maintain (V01, 2026-09-28)

Site address once published: https://hsiutingyu.github.io/umg/

The site is a pkgdown build of the package's own help pages, the three vignettes, NEWS.md, and inst/CITATION. It was built and checked in a Cowork session on 2026-09-28 (pkgdown 2.2.1, R 4.3.3): `check_pkgdown()` reported no problems, the build finished with no errors, and all 1,527 internal links resolve.

## What changed in this folder

| Path | Change |
|---|---|
| `docs/` (new, repository root) | The built site, 200 files, about 8 MB. GitHub Pages serves this folder. It includes an empty `.nojekyll` file; keep it. Without it GitHub Pages runs Jekyll over the folder, and Jekyll may render pkgdown's `.md` companion files (for example `index.md`) as pages that collide with the real `.html` pages. `pkgdown::build_site()` leaves the file in place when it rebuilds. |
| `umg/_pkgdown.yml` (new) | Site configuration: address, output folder `../docs`, source links that include the `umg/` subfolder, grouped function reference, navbar. |
| `umg/.Rbuildignore` | Adds `^_pkgdown\.yml$` so the config file never enters the CRAN tarball. |
| `umg/DESCRIPTION` | `URL:` now lists the site first, then the GitHub repository. |
| `umg/inst/CITATION` | The software citation points to the site; the companion-manuscript entry and its footer are removed (HT decision: the site does not list the manuscript while it is under review). |
| `umg/README.md` | Installation now shows `remotes::install_github("hsiutingyu/umg", subdir = "umg")`; the Citation section points to `citation("umg")` instead of the manuscript. README is the site's home page. |
| `umg/NEWS.md` | The four `<doi:...>` references in the 0.6.1 entry are now `[doi:...](https://doi.org/...)` links; the old form produced dead links on the Changelog page. Displayed text is unchanged. |
| `umg/build/` (removed, moved to `_to_delete/umg_build_stale_20260928/`) | A stale build artifact (`vignette.rds`) with no matching `inst/doc/`. While it was present, `remotes::install_github()` and `pkgdown::build_site()` both failed ("Output(s) listed in 'build/vignette.rds' but not in package"). `R CMD build` regenerates this folder, so the CRAN tarball is unaffected (verified: a full build still contains `build/vignette.rds` and the three vignette HTML files). |

None of these changes touches R code, tests, or any computed result.

## Step 1. Commit and push (GitHub Desktop)

1. Open GitHub Desktop, repository `umg`.
2. In the Changes list you will see `docs/` (many new files), the six edited files above, and `umg/build/vignette.rds` as deleted. The two `winbuilder_devel/` logs were already modified before this session; untick them if they should not go into this commit.
3. Summary: `Add pkgdown documentation site`. Commit to main, then Push origin.

## Step 2. Switch on GitHub Pages (one time)

1. On github.com open `hsiutingyu/umg`, then Settings, then Pages (left menu).
2. Under "Build and deployment": Source = Deploy from a branch; Branch = `main`; folder = `/docs`. Save.
3. Wait one or two minutes, then open https://hsiutingyu.github.io/umg/.

## Step 3. Show the link on the repository page (one time)

On the repository's main page, click the gear icon next to "About", tick "Use your GitHub Pages website", and save. The site link then appears at the top right of the repository.

## Rebuilding the site after a change

In R, with the working directory set to `2608_CRAN_UMG` (the folder that contains `umg/` and `docs/`):

```r
# install.packages("pkgdown")   # once
pkgdown::build_site("umg")
```

This rewrites `docs/`. Commit and push as in Step 1. For every vignette chunk to run, `lavaan`, `lme4`, `ggplot2`, and `DiagrammeR` must be installed. Rebuild after each CRAN release so the version number in the navbar matches.

## Timing relative to CRAN

- The CRAN resubmission is 0.6.1 as built in `umg_0.6.1.tar.gz` (2026-09-23). The edits above are not in that tarball; they ship with the next CRAN version, and CRAN's copy keeps the GitHub URL until then.
- When 0.6.1 is accepted, tag `v0.6.1` on commit `9ee6a25`, not on the site commit. Checked 2026-09-28: the `umg/` folder at `9ee6a25` matches `umg_0.6.1.tar.gz` in every R, Rd, test, and vignette file (DESCRIPTION differs only in the `Packaged:` line and line endings).
- Before the next CRAN submission, confirm the site is live. CRAN's URL check reports a DESCRIPTION URL that does not resolve.
- When CRAN accepts the package, add `install.packages("umg")` to the README installation block and rebuild the site.
