# ============================================================
# Title:  Graphviz/DOT export and rendering of UMG diagrams
# File:   dot.R (package umg)
# Author: H.-T. Yu
# Date:   2026-06-19
# ============================================================
# Exports a UMG to the Graphviz DOT language and, optionally, renders
# it through DiagrammeR for interactive HTML. The DOT backend maps the
# lexicon onto Graphviz primitives: node shape encodes support/role,
# fill encodes observability, plates become cluster subgraphs, and the
# four edge kinds use distinct arrowheads and line styles. Crossed
# plates (which Graphviz cannot represent as overlapping clusters) are
# rendered by assigning each vertex to its smallest enclosing plate; a
# note is emitted in that case.

.umg_dot_shape <- function(node) {
  switch(node$role,
    rv    = if (node$support == "categorical") "box" else "circle",
    det   = if (node$support == "categorical") "box" else "circle",
    par   = "diamond",
    const = "triangle")
}

# Graphviz prefers "gray" spellings; translate common grey* names.
.umg_dot_colour <- function(x) gsub("grey", "gray", x, fixed = TRUE)

# Covariance edges are double-headed and do not constrain the rank
# layout; Graphviz has no per-edge "curved" style (it warns and ignores
# style=curved), so the curvature is left to the engine's splines.
.umg_dot_edge_attr <- function(kind) {
  switch(kind,
    dep = "arrowhead=normal",
    det = "arrowhead=normal, style=dashed",
    mix = "arrowhead=open",
    cov = "dir=both, arrowhead=normal, arrowtail=normal, constraint=false")
}

#' Export a UMG as Graphviz DOT code
#'
#' Generates a directed-graph description in the Graphviz DOT language.
#' Node shape encodes support and inferential role, fill encodes
#' observability, plates become `cluster` subgraphs (nested clusters
#' for nested plates), and the four edge kinds are rendered with
#' distinct arrowheads and line styles. The output can be rendered by
#' any Graphviz engine or by [umg_render_dot()].
#'
#' @param model An object of class `umg`.
#' @param file Optional path; when supplied, the DOT code is written
#'   there and the path returned invisibly.
#' @param rankdir Graphviz layout direction: `"TB"` (default) or
#'   `"LR"`.
#' @param theme A `umg_theme` controlling fills.
#' @return A character vector of DOT code (invisibly when `file` is
#'   supplied).
#' @examples
#' cat(umg_to_dot(umg_factor("F", paste0("y", 1:3))), sep = "\n")
#' @export
umg_to_dot <- function(model, file = NULL, rankdir = c("TB", "LR"),
                       theme = umg_theme()) {
  stopifnot(inherits(model, "umg"))
  rankdir <- match.arg(rankdir)
  theme <- .umg_as_theme(theme)

  plates <- model$plates
  pnames <- vapply(plates, `[[`, character(1), "name")
  # assign each vertex to its smallest enclosing plate; plates cross
  # (as opposed to nest) when a vertex belongs to two plates neither of
  # which encloses the other
  size <- vapply(plates, function(p) length(p$members), integer(1))
  crossed <- FALSE
  vertex_plate <- stats::setNames(rep(NA_character_, length(model$nodes)),
                                  names(model$nodes))
  for (v in names(model$nodes)) {
    holding <- which(vapply(plates, function(p) v %in% p$members,
                            logical(1)))
    if (length(holding) > 1L) {
      for (a in holding) for (b in holding)
        if (a < b && !.umg_plate_within(model, pnames[a], pnames[b]) &&
            !.umg_plate_within(model, pnames[b], pnames[a]))
          crossed <- TRUE
    }
    if (length(holding))
      vertex_plate[v] <- pnames[holding[which.min(size[holding])]]
  }

  node_line <- function(v) {
    nd <- model$nodes[[v]]
    fill <- .umg_dot_colour(nd$fill %||%
      (if (nd$observed && nd$role == "rv") theme$observed_fill
       else theme$latent_fill))
    extra <- if (nd$role == "det") ", peripheries=2" else ""
    sprintf(
      '    "%s" [label="%s", shape=%s, style=filled, fillcolor="%s"%s];',
      v, .umg_plain(nd$label %||% v), .umg_dot_shape(nd), fill, extra)
  }

  out <- c("digraph UMG {",
           sprintf("  graph [rankdir=%s, compound=true];", rankdir),
           "  node [fontname=\"sans\"];")

  # plate clusters (parents first); nested plates nested inside parents
  children_of <- function(parent)
    pnames[vapply(plates, function(p)
      identical(p$parent, parent), logical(1))]

  emit_cluster <- function(pname, indent) {
    p <- plates[[match(pname, pnames)]]
    pad <- strrep(" ", indent)
    lines <- c(sprintf('%ssubgraph "cluster_%s" {', pad, pname),
               sprintf('%s  label="%s"; style=rounded; color="%s";',
                       pad, p$index, .umg_dot_colour(theme$plate_col)))
    for (v in names(vertex_plate)[vertex_plate == pname & !is.na(vertex_plate)])
      lines <- c(lines, paste0(pad, node_line(v)))
    for (ch in children_of(pname))
      lines <- c(lines, emit_cluster(ch, indent + 2L))
    c(lines, paste0(pad, "}"))
  }

  for (pname in pnames[vapply(plates, function(p) is.null(p$parent),
                              logical(1))])
    out <- c(out, emit_cluster(pname, 2L))

  # vertices outside any plate
  for (v in names(model$nodes))
    if (is.na(vertex_plate[v])) out <- c(out, node_line(v))

  # edges
  for (e in model$edges) {
    lab <- (if (!is.null(e$fixed)) as.character(e$fixed)
            else e$label) %||% ""
    labattr <- if (nzchar(lab))
      sprintf(', label="%s"', .umg_plain(lab)) else ""
    out <- c(out, sprintf('  "%s" -> "%s" [%s%s];',
                          e$from, e$to, .umg_dot_edge_attr(e$kind), labattr))
  }
  if (crossed)
    out <- c(out,
      "  // note: crossed plates rendered by smallest-enclosing assignment")
  out <- c(out, "}")

  if (!is.null(file)) {
    writeLines(out, con = file)
    return(invisible(out))
  }
  out
}

#' Render a UMG through DiagrammeR (Graphviz)
#'
#' Renders the DOT export of a UMG to an interactive HTML widget using
#' \pkg{DiagrammeR}'s Graphviz engine, suitable for notebooks, Shiny,
#' and \pkg{rmarkdown} HTML output.
#'
#' @param model An object of class `umg`.
#' @param ... Passed to [umg_to_dot()].
#' @return A `grViz`/`htmlwidget` object.
#' @examplesIf requireNamespace("DiagrammeR", quietly = TRUE)
#' umg_render_dot(umg_irt("2PL"))
#' @export
umg_render_dot <- function(model, ...) {
  .umg_require("DiagrammeR", "umg_render_dot")
  dot <- paste(umg_to_dot(model, ...), collapse = "\n")
  DiagrammeR::grViz(dot)
}
