# ============================================================
# Title:  ggplot2 rendering backend for UMG diagrams
# File:   ggplot.R (package umg)
# Author: H.-T. Yu
# Date:   2026-06-19
# ============================================================
# A ggplot2 backend that mirrors the channel allocation of the grid
# renderer: fill encodes observability, shape encodes support and
# role, plates are rectangles, and the four edge kinds are drawn with
# distinct line and arrowhead styles. Returning a ggplot object lets a
# diagram be composed, themed, and saved with the rest of a user's
# ggplot2 workflow.

# Internal: ggplot2 point-shape code for a vertex (filled shapes 21-24
# so that fill encodes observability independently of outline).
.umg_gg_shape <- function(node) {
  switch(node$role,
    rv    = if (node$support == "categorical") 22L else 21L,  # square / circle
    det   = if (node$support == "categorical") 22L else 21L,
    par   = 23L,                                              # diamond
    const = 24L)                                              # triangle
}

#' Render a UMG with ggplot2
#'
#' Produces a \pkg{ggplot2} rendering of a UMG using the same visual
#' grammar as [plot.umg()]: fill encodes observability, point shape
#' encodes support and inferential role, plates are drawn as
#' rectangles, and the four edge kinds are distinguished by line type
#' and arrowhead. The returned object is an ordinary ggplot and can be
#' further customised, faceted, or saved with [ggplot2::ggsave()].
#'
#' @param model An object of class `umg`; layout is computed if absent.
#' @param theme A `umg_theme` object, or a style name passed to
#'   [umg_theme()] (`"journal"`, `"slide"`, `"cb"`).
#' @param node_size Point size for vertices.
#' @param text_size Text size for vertex labels.
#' @param orientation Layer direction passed to [umg_layout()]
#'   (`"TB"` or `"LR"`).
#' @param ... Passed to [umg_layout()] when a layout is absent.
#' @return A ggplot object.
#' @examplesIf requireNamespace("ggplot2", quietly = TRUE)
#' umg_ggplot(umg_factor("F", paste0("y", 1:4)))
#' @export
umg_ggplot <- function(model, theme = umg_theme(), node_size = 14,
                       text_size = 3.2, orientation = NULL, ...) {
  .umg_require("ggplot2", "umg_ggplot")
  theme <- .umg_as_theme(theme)
  if (is.null(model$layout))
    model <- umg_layout(model, orientation = orientation, ...)
  lay <- model$layout$vertices
  rects <- model$layout$plates

  # vertex aesthetics
  lay$fill <- vapply(lay$name, function(nm) {
    nd <- model$nodes[[nm]]
    nd$fill %||% (if (nd$observed && nd$role == "rv")
      theme$observed_fill else theme$latent_fill)
  }, character(1))
  lay$shape <- vapply(lay$name, function(nm)
    .umg_gg_shape(model$nodes[[nm]]), integer(1))
  lay$label <- vapply(lay$name, function(nm)
    .umg_plain(model$nodes[[nm]]$label %||% nm), character(1))

  pos <- function(nm) c(lay$x[match(nm, lay$name)],
                        lay$y[match(nm, lay$name)])

  # edge data; endpoints are pulled back to the node boundary (as in
  # the grid backend) so that arrowheads are visible rather than
  # hidden underneath the vertex glyphs drawn on top
  node_r <- theme$node_r
  seg <- data.frame(x = numeric(0), y = numeric(0), xend = numeric(0),
                    yend = numeric(0), kind = character(0),
                    label = character(0), lx = numeric(0), ly = numeric(0),
                    stringsAsFactors = FALSE)
  skipped <- 0L
  for (e in model$edges) {
    p <- pos(e$from); q <- pos(e$to)
    d <- q - p
    len <- sqrt(sum(d^2))
    if (len < 2 * node_r) { skipped <- skipped + 1L; next }
    u <- d / len
    a <- p + u * node_r; b <- q - u * node_r
    lab <- (if (!is.null(e$fixed)) as.character(e$fixed)
            else e$label) %||% ""
    seg <- rbind(seg, data.frame(
      x = a[1], y = a[2], xend = b[1], yend = b[2], kind = e$kind,
      label = .umg_plain(lab), lx = (p[1] + q[1]) / 2 + 0.18,
      ly = (p[2] + q[2]) / 2 + 0.18, stringsAsFactors = FALSE))
  }
  if (skipped)
    warning(skipped, " edge(s) not drawn: endpoints closer than ",
            "2 * node_r; supply coords via umg_layout() to separate ",
            "the vertices.", call. = FALSE)

  g <- ggplot2::ggplot()

  # plates
  if (length(rects)) {
    pr <- do.call(rbind, lapply(rects, function(r)
      data.frame(x0 = r$x0, x1 = r$x1, y0 = r$y0, y1 = r$y1,
                 index = r$index, stringsAsFactors = FALSE)))
    g <- g + ggplot2::geom_rect(
      data = pr, ggplot2::aes(xmin = .data[["x0"]], xmax = .data[["x1"]],
                              ymin = .data[["y0"]], ymax = .data[["y1"]]),
      fill = NA, colour = theme$plate_col, linewidth = 0.4) +
      ggplot2::geom_text(
        data = pr, ggplot2::aes(x = .data[["x1"]] - 0.1,
                                y = .data[["y0"]] + 0.12,
                                label = .data[["index"]]),
        hjust = 1, vjust = 0, size = text_size * 0.8, fontface = "italic")
  }

  # directed edges: dep/det carry a closed arrowhead, mix an open one
  # (the same distinction as the grid and DOT backends)
  dir_seg <- seg[seg$kind %in% c("dep", "det"), , drop = FALSE]
  if (nrow(dir_seg)) {
    dir_seg$lty <- ifelse(dir_seg$kind == "det", "dashed", "solid")
    g <- g + ggplot2::geom_segment(
      data = dir_seg,
      ggplot2::aes(x = .data[["x"]], y = .data[["y"]],
                   xend = .data[["xend"]], yend = .data[["yend"]],
                   linetype = .data[["lty"]]),
      arrow = ggplot2::arrow(length = ggplot2::unit(2.4, "mm"),
                             type = "closed"),
      colour = theme$edge_col, linewidth = 0.5) +
      ggplot2::scale_linetype_identity()
  }
  mix_seg <- seg[seg$kind == "mix", , drop = FALSE]
  if (nrow(mix_seg)) {
    g <- g + ggplot2::geom_segment(
      data = mix_seg,
      ggplot2::aes(x = .data[["x"]], y = .data[["y"]],
                   xend = .data[["xend"]], yend = .data[["yend"]]),
      arrow = ggplot2::arrow(length = ggplot2::unit(2.4, "mm"),
                             type = "open"),
      colour = theme$edge_col, linewidth = 0.5)
  }
  # covariance edges (curved, double-headed)
  cov_seg <- seg[seg$kind == "cov", , drop = FALSE]
  if (nrow(cov_seg)) {
    g <- g + ggplot2::geom_curve(
      data = cov_seg,
      ggplot2::aes(x = .data[["x"]], y = .data[["y"]],
                   xend = .data[["xend"]], yend = .data[["yend"]]),
      curvature = theme$cov_curvature,
      arrow = ggplot2::arrow(ends = "both",
                             length = ggplot2::unit(2, "mm"),
                             type = "closed"),
      colour = theme$edge_col, linewidth = 0.5)
  }
  # edge labels
  lab_seg <- seg[nzchar(seg$label), , drop = FALSE]
  if (nrow(lab_seg))
    g <- g + ggplot2::geom_text(
      data = lab_seg, ggplot2::aes(x = .data[["lx"]], y = .data[["ly"]],
                                   label = .data[["label"]]),
      size = text_size * 0.85)

  # vertices and labels; deterministic vertices get an inner ring so
  # that role is distinguishable, as in the grid backend
  det_lay <- lay[vapply(lay$name, function(nm)
    model$nodes[[nm]]$role == "det", logical(1)), , drop = FALSE]
  g <- g +
    ggplot2::geom_point(
      data = lay, ggplot2::aes(x = .data[["x"]], y = .data[["y"]],
                               shape = .data[["shape"]],
                               fill = .data[["fill"]]),
      size = node_size, colour = theme$node_col, stroke = 0.6) +
    ggplot2::scale_shape_identity() +
    ggplot2::scale_fill_identity()
  if (nrow(det_lay))
    g <- g + ggplot2::geom_point(
      data = det_lay, ggplot2::aes(x = .data[["x"]], y = .data[["y"]],
                                   shape = .data[["shape"]]),
      size = node_size * 0.78, fill = NA, colour = theme$node_col,
      stroke = 0.4)
  g <- g +
    ggplot2::geom_text(
      data = lay, ggplot2::aes(x = .data[["x"]], y = .data[["y"]],
                               label = .data[["label"]]),
      size = text_size) +
    ggplot2::annotate("text", x = max(lay$x), y = max(lay$y) + 1,
                      label = paste0("[", model$badge, "]"),
                      size = text_size * 0.8, colour = theme$badge_col) +
    ggplot2::coord_equal(clip = "off") +
    ggplot2::theme_void()
  g
}

#' @rdname umg_ggplot
#' @param object An object of class `umg` (for the `autoplot` method).
#' @exportS3Method ggplot2::autoplot
autoplot.umg <- function(object, ...) {
  umg_ggplot(object, ...)
}
