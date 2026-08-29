# ============================================================
# Title:  Grid-graphics rendering of UMG diagrams
# File:   plot.R (package umg)
# Author: H.-T. Yu
# Date:   2026-06-18  (V02: theme support, node aesthetics, orientation)
# ============================================================

# Internal: map a vertex to a shape and a fill, honouring any
# node-level fill override (node$fill) and the active theme.
# Channel allocation (see article, Table 2):
#   fill -> observability; shape -> support; border/shape -> role.
.umg_glyph <- function(node, theme) {
  fill <- if (!is.null(node$fill)) node$fill
          else if (node$observed && node$role == "rv") theme$observed_fill
          else theme$latent_fill
  shape <- switch(node$role,
    rv    = if (node$support == "categorical") "square" else "circle",
    det   = if (node$support == "categorical") "square2" else "circle2",
    par   = "diamond",
    const = "triangle")
  list(fill = fill, shape = shape)
}

#' Plot a UMG with grid graphics
#'
#' Renders the diagram using the same channel allocation as the TikZ
#' lexicon: fill encodes observability, shape encodes support, border
#' and dedicated shapes encode role, and plates are rounded rectangles.
#' Appearance is governed by a theme (see [umg_theme()]); individual
#' vertices may override their fill by carrying a `fill` element.
#'
#' @param x An object of class `umg` (layout computed automatically if
#'   absent).
#' @param theme A `umg_theme` object (default [umg_theme()]), or a
#'   style name (`"journal"`, `"slide"`, `"cb"`).
#' @param parse_labels Logical; parse labels as plotmath. Defaults to
#'   the theme value. TeX `$` delimiters are stripped for display.
#' @param node_r Vertex radius in native units; defaults to the theme
#'   value.
#' @param orientation Layer direction passed to [umg_layout()]:
#'   `"TB"` (top to bottom, default) or `"LR"` (left to right).
#' @param ... Passed to [umg_layout()] when a layout is absent.
#' @return Invisibly `x` (with layout attached).
#' @export
plot.umg <- function(x, theme = umg_theme(), parse_labels = NULL,
                     node_r = NULL, orientation = NULL, ...) {
  theme <- .umg_as_theme(theme)
  if (is.null(parse_labels)) parse_labels <- isTRUE(theme$parse_labels)
  if (is.null(node_r)) node_r <- theme$node_r
  if (is.null(x$layout))
    x <- umg_layout(x, orientation = orientation, ...)
  lay <- x$layout$vertices
  rects <- x$layout$plates

  xr <- range(c(lay$x - 1.2, lay$x + 1.2,
                unlist(lapply(rects, function(r) c(r$x0, r$x1)))))
  yr <- range(c(lay$y - 1.2, lay$y + 1.2,
                unlist(lapply(rects, function(r) c(r$y0, r$y1)))))

  grid::grid.newpage()
  grid::pushViewport(grid::dataViewport(xscale = xr, yscale = yr))

  nat <- function(v) grid::unit(v, "native")

  # ----- plates (drawn first, back to front by area) --------------
  if (length(rects)) {
    areas <- vapply(rects, function(r) (r$x1 - r$x0) * (r$y1 - r$y0),
                    numeric(1))
    for (r in rects[order(-areas)]) {
      grid::grid.rect(x = nat((r$x0 + r$x1) / 2),
                      y = nat((r$y0 + r$y1) / 2),
                      width = nat(r$x1 - r$x0),
                      height = nat(r$y1 - r$y0),
                      just = "centre",
                      gp = grid::gpar(fill = NA, col = theme$plate_col,
                                      lwd = theme$plate_lwd))
      grid::grid.text(r$index,
                      x = nat(r$x1 - 0.1), y = nat(r$y0 + 0.12),
                      just = c("right", "bottom"),
                      gp = grid::gpar(cex = theme$plate_lab_cex,
                                      fontface = "italic"))
    }
  }

  pos <- function(nm) {
    i <- match(nm, lay$name)
    c(lay$x[i], lay$y[i])
  }

  # ----- edges ------------------------------------------------------
  shrink <- function(p, q, r) {
    d <- q - p
    len <- sqrt(sum(d^2))
    if (len < 2 * r) return(NULL)
    u <- d / len
    list(a = p + u * r, b = q - u * r)
  }
  skipped <- 0L
  for (e in x$edges) {
    p <- pos(e$from); q <- pos(e$to)
    if (e$kind == "cov") {
      s <- shrink(p, q, node_r)
      if (is.null(s)) { skipped <- skipped + 1L; next }
      grid::grid.curve(nat(s$a[1]), nat(s$a[2]),
                       nat(s$b[1]), nat(s$b[2]),
                       curvature = theme$cov_curvature, ncp = 8,
                       arrow = grid::arrow(ends = "both",
                                           length = grid::unit(2.2, "mm"),
                                           type = "closed"),
                       gp = grid::gpar(fill = theme$edge_col,
                                       col = theme$edge_col,
                                       lwd = theme$edge_lwd))
    } else {
      s <- shrink(p, q, node_r)
      if (is.null(s)) { skipped <- skipped + 1L; next }
      lty <- if (e$kind == "det") 2 else 1
      atype <- if (e$kind == "mix") "open" else "closed"
      grid::grid.lines(nat(c(s$a[1], s$b[1])), nat(c(s$a[2], s$b[2])),
                       arrow = grid::arrow(
                         length = grid::unit(theme$arrow_mm, "mm"),
                         type = atype),
                       gp = grid::gpar(fill = theme$edge_col,
                                       col = theme$edge_col,
                                       lwd = theme$edge_lwd, lty = lty))
    }
    lab <- (if (!is.null(e$fixed)) as.character(e$fixed)
            else e$label) %||% ""
    if (nzchar(lab)) {
      mid <- (p + q) / 2
      lab_disp <- .umg_plain(lab)
      grid::grid.text(if (parse_labels) tryCatch(parse(text = lab_disp),
                                                 error = function(z) lab_disp)
                      else lab_disp,
                      nat(mid[1] + 0.18), nat(mid[2] + 0.18),
                      gp = grid::gpar(cex = theme$edge_label_cex))
    }
  }
  if (skipped)
    warning(skipped, " edge(s) not drawn: endpoints closer than ",
            "2 * node_r; supply coords via umg_layout() to separate ",
            "the vertices.", call. = FALSE)

  # ----- vertices ---------------------------------------------------
  for (v in x$nodes) {
    g <- .umg_glyph(v, theme)
    p <- pos(v$name)
    gp <- grid::gpar(fill = g$fill, col = theme$node_col,
                     lwd = theme$node_lwd)
    if (g$shape %in% c("circle", "circle2")) {
      grid::grid.circle(nat(p[1]), nat(p[2]), r = nat(node_r), gp = gp)
      if (g$shape == "circle2")
        grid::grid.circle(nat(p[1]), nat(p[2]), r = nat(node_r * 0.85),
                          gp = grid::gpar(fill = NA, lwd = 0.8,
                                          col = theme$node_col))
    } else if (g$shape %in% c("square", "square2")) {
      grid::grid.rect(nat(p[1]), nat(p[2]),
                      width = nat(2 * node_r * 0.9),
                      height = nat(2 * node_r * 0.9), gp = gp)
      if (g$shape == "square2")
        grid::grid.rect(nat(p[1]), nat(p[2]),
                        width = nat(2 * node_r * 0.75),
                        height = nat(2 * node_r * 0.75),
                        gp = grid::gpar(fill = NA, lwd = 0.8,
                                        col = theme$node_col))
    } else if (g$shape == "diamond") {
      grid::grid.polygon(nat(p[1] + c(0, node_r, 0, -node_r)),
                         nat(p[2] + c(node_r, 0, -node_r, 0)), gp = gp)
    } else if (g$shape == "triangle") {
      grid::grid.polygon(nat(p[1] + c(0, node_r, -node_r)),
                         nat(p[2] + c(node_r, -node_r, -node_r)),
                         gp = gp)
    }
    lab_disp <- .umg_plain(v$label %||% v$name)
    grid::grid.text(if (parse_labels) tryCatch(parse(text = lab_disp),
                                               error = function(z) lab_disp)
                    else lab_disp,
                    nat(p[1]), nat(p[2]),
                    gp = grid::gpar(cex = theme$label_cex))
  }

  # ----- badge ------------------------------------------------------
  grid::grid.text(paste0("[", x$badge, "]"),
                  x = grid::unit(0.98, "npc"), y = grid::unit(0.98, "npc"),
                  just = c("right", "top"),
                  gp = grid::gpar(cex = theme$badge_cex,
                                  fontfamily = "sans",
                                  col = theme$badge_col))

  grid::popViewport()
  invisible(x)
}
