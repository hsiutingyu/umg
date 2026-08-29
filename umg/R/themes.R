# ============================================================
# Title:  Theming for UMG grid rendering
# File:   themes.R (package umg)
# Author: H.-T. Yu
# Date:   2026-06-18
# ============================================================
# A theme is a named list of visual constants consumed by plot.umg().
# Themes let the same diagram be rendered for a manuscript, a slide, or
# a colour-blind-safe handout without editing the model object.

#' Construct a UMG rendering theme
#'
#' Returns a named list of visual constants controlling colours, sizes,
#' and line weights for [plot.umg()]. The defaults reproduce the
#' grayscale lexicon of the accompanying article; `style = "slide"`
#' enlarges type and thickens strokes for projection, and
#' `style = "journal"` is the compact grayscale default. Any individual
#' element may be overridden through `...`.
#'
#' @param style One of `"journal"` (default), `"slide"`, or
#'   `"cb"` (a colour-blind-safe palette that adds hue to the
#'   observability cue while keeping fill luminance informative).
#' @param ... Named overrides for any theme element, e.g.
#'   `observed_fill = "grey80"`, `label_cex = 0.9`.
#' @return A named list of class `umg_theme`.
#' @examples
#' th <- umg_theme("slide", label_cex = 1.1)
#' @export
umg_theme <- function(style = c("journal", "slide", "cb"), ...) {
  style <- match.arg(style)
  base <- list(
    observed_fill = "grey85",
    latent_fill   = "white",
    node_col      = "black",
    node_lwd      = 1.2,
    node_r        = 0.42,
    edge_col      = "black",
    edge_lwd      = 1.1,
    arrow_mm      = 2.6,
    cov_curvature = 0.35,
    label_cex     = 0.8,
    edge_label_cex = 0.75,
    plate_col     = "grey30",
    plate_lwd     = 1.0,
    plate_lab_cex = 0.7,
    badge_col     = "grey25",
    badge_cex     = 0.7,
    parse_labels  = FALSE
  )
  if (style == "slide") {
    base$node_lwd <- 1.8; base$edge_lwd <- 1.8
    base$label_cex <- 1.05; base$edge_label_cex <- 0.95
    base$plate_lab_cex <- 0.9; base$arrow_mm <- 3.2
  } else if (style == "cb") {
    # Luminance still carries observability; hue is redundant backup.
    base$observed_fill <- "#9ecae1"   # observed: filled blue
    base$latent_fill   <- "#ffffff"   # latent: white
    base$node_col      <- "#08306b"
    base$edge_col      <- "#08306b"
    base$plate_col     <- "#6baed6"
  }
  override <- list(...)
  if (length(override)) {
    unknown <- setdiff(names(override), names(base))
    if (length(unknown)) {
      warning("Unknown theme element(s) ignored: ",
              paste(unknown, collapse = ", "))
      override <- override[setdiff(names(override), unknown)]
    }
    if (any(vapply(override, is.null, logical(1))))
      stop("Theme elements cannot be NULL.", call. = FALSE)
    base[names(override)] <- override
  }
  class(base) <- "umg_theme"
  base
}
