## Resubmission

This is a resubmission of a new package. Version has been bumped from
0.6.0 to 0.6.1. Both points raised in the review of 0.6.0 have been
addressed.

**References in DESCRIPTION.** The Description field now cites the
published results the package implements, in the requested auto-linking
form: plate notation, Buntine (1994) <doi:10.1613/jair.62>; the parameter
counting rule and scaling checks, Bollen (1989)
<doi:10.1002/9781118619179>; and the independence reader, which evaluates
the d-separation criterion of Geiger, Verma and Pearl (1990)
<doi:10.1002/net.3230200504> through the equivalent ancestral graph
criterion of Lauritzen, Dawid, Larsen and Leimer (1990)
<doi:10.1002/net.3230200503>. The graphical notation that the package
itself introduces is described in a manuscript still in preparation, so
no reference to it is available yet; the references given above are for
the established results the package builds on.

**Examples wrapped in \dontrun{}.** The package contained exactly one
such example, for `umg_eda_scaffold()`. It has been unwrapped. The
example now runs under roxygen2's `@examplesIf`, conditional on the
suggested package 'ggplot2' being installed, which is the convention
already used elsewhere in the package (`umg_ggplot()`,
`umg_render_dot()`). It executes in well under five seconds. The package
now contains no `\dontrun{}`.

No user-visible behaviour, function signature, or computed result
changed between 0.6.0 and 0.6.1.

## Test environments

* Local: Windows 11 x64 (build 26200), R 4.5.3 (2026-03-11 ucrt)
* win-builder: R Under development (unstable) (2026-09-21 r90579 ucrt)

## R CMD check results

0 errors | 0 warnings | 1 note

* checking CRAN incoming feasibility ... NOTE
  Maintainer: 'Hsiu-Ting Yu <hsiutingyu@gmail.com>'

  New submission

  Possibly misspelled words in DESCRIPTION:
    Bollen (26:49)
    Buntine (25:36)
    Dawid (30:29)
    Lauritzen (30:18)
    Leimer (30:47)
    UMG (9:13)
    Verma (28:43)
    observability (10:39)

The "New submission" NOTE is expected for a first submission. None of the
words reported is a misspelling. Bollen, Buntine, Dawid, Lauritzen,
Leimer and Verma are the surnames of the authors cited in the references
added above. "UMG" is the package's own initialism (Unified Model Graph,
the name of the notation it implements). "observability" is a standard
technical term in this domain: whether a variable is measured or
inferred.

The local Windows run additionally reports one environment-specific NOTE
("checking for detritus in the temp directory ... 'lastMiKTeXException'")
that is an artifact of the local MiKTeX installation used to typeset the
PDF manual. It does not appear on win-builder and is not expected on
CRAN's build systems.

## macOS pre-submission check

As with the previous submission, a macOS check could not be obtained:
`devtools::check_mac_release()` failed with a server-side error (HTTP
502) from mac.r-project.org.

## Downstream dependencies

There are currently no downstream dependencies for this package, as it
has not previously been released to CRAN.
