# ============================================================
# Title:  Layered layout for UMG diagrams
# File:   layout.R (package umg)
# Author: H.-T. Yu
# Date:   2026-06-12
# ============================================================

#' Compute a layered layout for a UMG
#'
#' Assigns coordinates by longest-path layering on the directed
#' subgraph: parameters and constants at the top, observed leaves at
#' the bottom, vertices spread horizontally within layers. Plate
#' rectangles are computed as padded bounding boxes of their members,
#' with padding growing by nesting depth so nested plates remain
#' visually distinct. Coordinates can be overridden by supplying a
#' `coords` data frame, which is the recommended route for
#' publication figures.
#'
#' @param model An object of class `umg`.
#' @param coords Optional data frame with columns `name`, `x`, `y`
#'   overriding computed positions.
#' @param hgap,vgap Horizontal and vertical spacing between vertices.
#' @param orientation Layer direction: `"TB"` (top to bottom, the
#'   default) places sources at the top and observed leaves at the
#'   bottom; `"LR"` lays the layers out left to right. `NULL` is treated
#'   as `"TB"`.
#' @return The model with a `layout` component added: a data frame of
#'   vertex coordinates and a list of plate rectangles.
#' @export
umg_layout <- function(model, coords = NULL, hgap = 1.6, vgap = 1.8,
                       orientation = c("TB", "LR")) {
  if (is.null(orientation)) orientation <- "TB"
  orientation <- match.arg(orientation)
  stopifnot(inherits(model, "umg"))
  nodes <- model$nodes
  node_names <- names(nodes)

  directed <- Filter(function(e) e$kind %in% c("dep", "det", "mix"),
                     model$edges)

  # ----- longest-path layering (topological order exists by W1) ---
  layer <- stats::setNames(rep(0L, length(node_names)), node_names)
  changed <- TRUE
  guard <- 0L
  while (changed && guard < length(node_names) + 2L) {
    changed <- FALSE
    guard <- guard + 1L
    for (e in directed) {
      if (layer[e$to] < layer[e$from] + 1L) {
        layer[e$to] <- layer[e$from] + 1L
        changed <- TRUE
      }
    }
  }

  # ----- horizontal positions within layers ----------------------
  xs <- numeric(length(node_names))
  names(xs) <- node_names
  for (l in sort(unique(layer))) {
    members <- node_names[layer == l]
    offset <- -(length(members) - 1) / 2
    xs[members] <- (seq_along(members) - 1 + offset) * hgap
  }
  if (orientation == "TB") {
    lay <- data.frame(name = node_names,
                      x = xs[node_names],
                      y = -as.numeric(layer[node_names]) * vgap,
                      stringsAsFactors = FALSE)
  } else {
    # left-to-right: layer indexes the horizontal axis, the within-layer
    # spread becomes the vertical axis.
    lay <- data.frame(name = node_names,
                      x = as.numeric(layer[node_names]) * vgap,
                      y = xs[node_names],
                      stringsAsFactors = FALSE)
  }

  # ----- user overrides -------------------------------------------
  if (!is.null(coords)) {
    stopifnot(all(c("name", "x", "y") %in% names(coords)))
    idx <- match(coords$name, lay$name)
    ok <- !is.na(idx)
    lay$x[idx[ok]] <- coords$x[ok]
    lay$y[idx[ok]] <- coords$y[ok]
  }

  # ----- plate rectangles ------------------------------------------
  plate_names <- vapply(model$plates, `[[`, character(1), "name")
  depth <- function(p) {
    d <- 0L
    while (!is.null(p$parent)) {
      d <- d + 1L
      p <- model$plates[[match(p$parent, plate_names)]]
    }
    d
  }
  # deeper plates get less padding so parents enclose children
  max_depth <- if (length(model$plates))
    max(vapply(model$plates, depth, integer(1))) else 0L
  rects <- lapply(model$plates, function(p) {
    m <- lay[lay$name %in% p$members, , drop = FALSE]
    pad <- 0.55 + 0.35 * (max_depth - depth(p))
    list(name = p$name, index = p$index,
         x0 = min(m$x) - pad, x1 = max(m$x) + pad,
         y0 = min(m$y) - pad, y1 = max(m$y) + pad)
  })

  model$layout <- list(vertices = lay, plates = rects)
  model
}
