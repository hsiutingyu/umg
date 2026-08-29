# ============================================================
# Title:  Tabular export, summaries, and lavaan round-tripping
# File:   export_model.R (package umg)
# Author: H.-T. Yu
# Date:   2026-06-25
# ============================================================
# Accessors that expose a UMG as ordinary data frames, a richer
# summary method, and an inverse converter that emits lavaan model
# syntax from a diagram. Together with umg_from_lavaan() these make the
# "diagram is the model" correspondence operational in both directions.

#' Coerce a UMG to a data frame
#'
#' Returns the vertices or the edges of a diagram as a tidy data frame,
#' which is convenient for inspection, tabulation in a manuscript, and
#' programmatic edits before re-assembling with [umg_model()].
#'
#' @param x An object of class `umg`.
#' @param row.names Unused; present for S3 consistency.
#' @param optional Unused; present for S3 consistency.
#' @param what `"edges"` (default) returns one row per edge with
#'   columns `from`, `to`, `kind`, `label`, and `fixed`; `"vertices"`
#'   returns one row per vertex with columns `name`, `label`,
#'   `observed`, `support`, `role`, `dist`, `fill`, and `annot`.
#' @param ... Ignored.
#' @return A data frame.
#' @examples
#' as.data.frame(umg_factor("F", paste0("y", 1:3)))
#' as.data.frame(umg_factor("F", paste0("y", 1:3)), what = "vertices")
#' @export
as.data.frame.umg <- function(x, row.names = NULL, optional = FALSE,
                              what = c("edges", "vertices"), ...) {
  what <- match.arg(what)
  if (what == "vertices") {
    nd <- x$nodes
    chr <- function(field) vapply(nd, function(v) {
      val <- v[[field]]; if (is.null(val)) NA_character_ else as.character(val)
    }, character(1))
    data.frame(
      name = vapply(nd, `[[`, character(1), "name"),
      label = chr("label"),
      observed = vapply(nd, function(v) isTRUE(v$observed), logical(1)),
      support = chr("support"),
      role = chr("role"),
      dist = chr("dist"),
      fill = chr("fill"),
      annot = chr("annot"),
      stringsAsFactors = FALSE, row.names = NULL)
  } else {
    ed <- x$edges
    if (!length(ed))
      return(data.frame(from = character(0), to = character(0),
                        kind = character(0), label = character(0),
                        fixed = numeric(0), stringsAsFactors = FALSE))
    data.frame(
      from = vapply(ed, `[[`, character(1), "from"),
      to = vapply(ed, `[[`, character(1), "to"),
      kind = vapply(ed, `[[`, character(1), "kind"),
      label = vapply(ed, function(e) e$label %||% "", character(1)),
      fixed = vapply(ed, function(e)
        if (is.null(e$fixed)) NA_real_ else as.numeric(e$fixed), numeric(1)),
      stringsAsFactors = FALSE, row.names = NULL)
  }
}

#' Summarise a UMG
#'
#' Produces a structured summary of a diagram: vertex counts broken
#' down by observability, support, and inferential role; edge counts by
#' kind; the plate structure; and a one-line identification snapshot
#' from [umg_count_parameters()] and [umg_check_scaling()].
#'
#' @param object An object of class `umg`.
#' @param ... Ignored.
#' @return An object of class `summary.umg` (a list), printed by its
#'   own method.
#' @examples
#' summary(umg_sem(list(F1 = paste0("y", 1:3), F2 = paste0("y", 4:6)),
#'                 structural = list(c("F1", "F2"))))
#' @export
summary.umg <- function(object, ...) {
  nd <- object$nodes
  role <- vapply(nd, `[[`, character(1), "role")
  support <- vapply(nd, `[[`, character(1), "support")
  observed <- vapply(nd, function(v) isTRUE(v$observed), logical(1))
  kinds <- vapply(object$edges, `[[`, character(1), "kind")
  scaling <- umg_check_scaling(object)
  cnt <- umg_count_parameters(object)
  out <- list(
    badge = object$badge,
    n_vertices = length(nd),
    n_observed = sum(observed & role == "rv"),
    n_latent = sum(!observed & role == "rv"),
    n_param = sum(role == "par"),
    n_const = sum(role == "const"),
    n_categorical = sum(support == "categorical"),
    role_table = table(role),
    edge_table = if (length(kinds)) table(kinds) else integer(0),
    n_plates = length(object$plates),
    plate_names = vapply(object$plates, `[[`, character(1), "name"),
    df = cnt$df,
    free_total = cnt$free_total,
    data_information = cnt$data_information,
    unscaled = if (nrow(scaling)) scaling$vertex[!scaling$scaled]
               else character(0)
  )
  class(out) <- "summary.umg"
  out
}

#' @rdname summary.umg
#' @param x An object of class `summary.umg`.
#' @export
print.summary.umg <- function(x, ...) {
  cat("Unified Model Graph summary (", x$badge, " badge)\n", sep = "")
  cat("-----------------------------------------------\n")
  cat(sprintf("Vertices: %d  (observed rv: %d, latent rv: %d, parameters: %d, constants: %d)\n",
              x$n_vertices, x$n_observed, x$n_latent, x$n_param, x$n_const))
  cat(sprintf("Categorical-support vertices: %d\n", x$n_categorical))
  if (length(x$edge_table))
    cat("Edges:", paste(names(x$edge_table), x$edge_table,
                        sep = "=", collapse = ", "), "\n")
  cat(sprintf("Plates: %d%s\n", x$n_plates,
              if (x$n_plates) paste0(" (", paste(x$plate_names,
                collapse = ", "), ")") else ""))
  cat(sprintf("Counting rule: %d data moments, %d free parameters, df = %d\n",
              x$data_information, x$free_total, x$df))
  if (length(x$unscaled))
    cat("Unscaled latent vertices:", paste(x$unscaled, collapse = ", "),
        "\n")
  invisible(x)
}

#' Generate lavaan model syntax from a UMG
#'
#' Emits \pkg{lavaan} model syntax from a diagram, the inverse of
#' [umg_from_lavaan()]. The translation uses an explicit, documented
#' convention. A directed (`dep`) edge from a latent vertex to an
#' observed vertex is a measurement loading (`=~`); every other directed
#' edge is a regression (`~`), so that observed-to-observed paths,
#' observed-to-latent causes (as in MIMIC), and latent-to-latent
#' structural paths are all written with `~`. Symmetric (`cov`) edges
#' become covariances (`~~`). Fixed edge values are written as
#' `value * variable`; free edges are left for lavaan to estimate, and
#' residual variances are left implicit. A vertex carrying a mean
#' annotation in its `annot` field (as written by [umg_from_lavaan()]
#' from a fit with a mean structure) yields an intercept line:
#' `mean = free` becomes `v ~ 1`, and `mean = <value>` becomes
#' `v ~ <value>*1`; `mean = fixed` (a mean fixed at a sample value, as
#' for exogenous covariates under `fixed.x = TRUE`) emits nothing,
#' because a refit fixes it the same way. A growth model therefore
#' round-trips with its mean structure intact, whether refitted with
#' `lavaan::growth()` or with `lavaan::cfa()`.
#'
#' The convention cannot recover a measurement interpretation of a
#' latent-to-latent relation (for example a second-order factor loading
#' on first-order factors), which is written as a latent regression; a
#' message flags this case so the relevant lines can be changed from
#' `~` to `=~` by hand if a higher-order measurement model is intended.
#' Mixing (`mix`) and deterministic (`det`) edges, and the categorical
#' latent structure of mixture and diagnostic models, have no basic
#' lavaan syntax and are omitted with a warning.
#'
#' @param model An object of class `umg`.
#' @param file Optional path; when supplied the syntax is written there
#'   and the path is returned invisibly.
#' @return A single character string of lavaan syntax (invisibly when
#'   `file` is supplied).
#' @seealso [umg_from_lavaan()]
#' @examples
#' cat(umg_to_lavaan(umg_sem(
#'   measurement = list(F1 = paste0("y", 1:3), F2 = paste0("y", 4:6)),
#'   structural  = list(c("F1", "F2")))))
#' @export
umg_to_lavaan <- function(model, file = NULL) {
  stopifnot(inherits(model, "umg"))
  nodes <- model$nodes
  is_latent <- function(v) !nodes[[v]]$observed && nodes[[v]]$role == "rv"

  spec <- function(var, fixed)
    if (!is.null(fixed)) paste0(fixed, "*", var) else var

  loadings <- list()   # factor -> character vector of indicator specs
  regress  <- list()   # outcome -> character vector of predictor specs
  covlines <- character(0)
  latent_latent <- FALSE
  dropped <- FALSE

  for (e in model$edges) {
    if (e$kind == "cov") {
      if (nodes[[e$from]]$role == "rv" && nodes[[e$to]]$role == "rv")
        covlines <- c(covlines,
                      paste0(e$from, " ~~ ", spec(e$to, e$fixed)))
      next
    }
    if (e$kind %in% c("mix", "det")) { dropped <- TRUE; next }
    # dep edge: classify as measurement or regression
    if (is_latent(e$from) && !is_latent(e$to) && nodes[[e$to]]$role == "rv") {
      loadings[[e$from]] <- c(loadings[[e$from]], spec(e$to, e$fixed))
    } else if (nodes[[e$from]]$role %in% c("rv", "det") &&
               nodes[[e$to]]$role %in% c("rv", "det")) {
      if (is_latent(e$from) && is_latent(e$to)) latent_latent <- TRUE
      regress[[e$to]] <- c(regress[[e$to]], spec(e$from, e$fixed))
    } else {
      dropped <- TRUE  # parameter/constant source: no plain lavaan term
    }
  }

  lines <- character(0)
  if (length(loadings)) {
    lines <- c(lines, "# measurement model")
    for (f in names(loadings))
      lines <- c(lines, paste0(f, " =~ ", paste(loadings[[f]],
                                                collapse = " + ")))
  }
  if (length(regress)) {
    lines <- c(lines, "# structural / regression model")
    for (o in names(regress))
      lines <- c(lines, paste0(o, " ~ ", paste(regress[[o]],
                                               collapse = " + ")))
  }
  if (length(covlines))
    lines <- c(lines, "# (co)variances", covlines)

  # mean structure: intercept lines from "mean = ..." annotations
  meanlines <- character(0)
  for (v in names(nodes)) {
    if (nodes[[v]]$role != "rv") next
    mv <- .umg_mean_annot(nodes[[v]])
    if (is.null(mv) || identical(mv, "fixed")) next
    meanlines <- c(meanlines,
                   if (identical(mv, "free")) paste0(v, " ~ 1")
                   else paste0(v, " ~ ", mv, "*1"))
  }
  if (length(meanlines))
    lines <- c(lines, "# intercepts / means", meanlines)

  if (latent_latent)
    message("umg_to_lavaan(): latent-to-latent paths written as ",
            "regressions ('~'); change to '=~' by hand if a higher-order ",
            "measurement model is intended.")
  if (dropped)
    warning("umg_to_lavaan(): mixing/deterministic edges or ",
            "parameter-sourced edges were omitted; they have no basic ",
            "lavaan syntax.", call. = FALSE)

  syntax <- paste(lines, collapse = "\n")
  if (!is.null(file)) {
    writeLines(syntax, con = file)
    return(invisible(syntax))
  }
  syntax
}
