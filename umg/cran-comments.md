## Submission

This is the first submission of umg to CRAN.

## Test environments

* Local: Windows 11 x64 (build 26200), R 4.5.3 (2026-03-11 ucrt)
* win-builder (R-devel, 2026-09-10 r90519)
* win-builder (R-release, R 4.6.1, 2026-06-24)

## R CMD check results

0 errors | 0 warnings | 1 note, on all three environments above.

* checking CRAN incoming feasibility ... NOTE
  Maintainer: 'Hsiu-Ting Yu <hsiutingyu@gmail.com>'

  New submission

  Possibly misspelled words in DESCRIPTION:
    UMG (9:13)
    observability (10:39)

This NOTE is expected and unavoidable for a first submission of a new
package. Neither flagged word is a misspelling: "UMG" is the package's own
initialism (Unified Model Graph, the name of the graphical notation the
package implements), and "observability" is a standard technical term in
this domain (whether a variable is measured or inferred).

The local Windows run additionally reports one environment-specific NOTE
("checking for detritus in the temp directory ... 'lastMiKTeXException'")
that is an artifact of the local MiKTeX installation used to typeset the
PDF manual. It does not appear on either win-builder check and is not
expected to appear on CRAN's build systems.

## macOS pre-submission check

A macOS check was attempted via `devtools::check_mac_release()` but could
not be completed: the CRAN macOS builder service (mac.r-project.org)
returned a transient server error (HTTP 502) at submission time. No
Windows- or platform-specific issues were found on any of the three
environments above; CRAN's own incoming checks will additionally build
and test the package on macOS and Linux.

## Downstream dependencies

There are currently no downstream dependencies for this package, as it
has not previously been released to CRAN.
