# ============================================================
# Title:  Additional fitted-object converters (V03 expansion)
# File:   converters_extra.R (package umg)
# Author: H.-T. Yu
# Date:   2026-06-19
# ============================================================
# Converters that translate fitted objects from further modelling
# packages into UMG diagrams: brms (Bayesian multilevel), OpenMx (RAM
# path models), and qgraph/psychonetrics-style weighted adjacency
# matrices (network psychometrics). Each guards its suggested
# dependency and falls back to an informative error.

#' Build a UMG from a brms model
#'
#' Translates a Bayesian multilevel model fitted with \pkg{brms} into a
#' nested-plate UMG. The random-effect structure is parsed from the
#' model formula with the same engine as [umg_from_lmer()], and the
#' fixed-effect population parameters are rendered in their
#' prior-closed (Bayesian) form, consistent with the article's
#' treatment of priors as parameter promotion.
#'
#' @param object A fitted `brmsfit` object, or a model formula using
#'   lme4-style random-effect syntax.
#' @param data Optional data frame; only used to label index sizes.
#' @return An object of class `umg`.
#' @export
umg_from_brms <- function(object, data = NULL) {
  .umg_require("lme4", "umg_from_brms")
  if (inherits(object, "formula")) {
    form <- object
  } else {
    .umg_require("brms", "umg_from_brms")
    form <- tryCatch(object$formula$formula, error = function(e) NULL)
    if (is.null(form)) form <- stats::formula(object)
  }
  .umg_from_mixed(form, data = data, bayesian = TRUE)
}

#' Build a UMG from an OpenMx RAM model
#'
#' Translates a reticular action model (RAM) fitted or specified with
#' \pkg{OpenMx} into a UMG. Manifest variables become observed
#' vertices and latent variables become latent vertices; nonzero
#' entries of the asymmetric matrix `A` become directed `dep` edges
#' (with fixed values shown for non-free paths), and off-diagonal
#' entries of the symmetric matrix `S` become `cov` edges. This exposes
#' the path-diagram content of a RAM specification in the UMG lexicon.
#'
#' @param object An `MxModel` containing RAM matrices `A`, `S`, and
#'   `F` (the standard `mxModel(type = "RAM")` form).
#' @param plate_index Index label for the person plate.
#' @return An object of class `umg`.
#' @export
umg_from_OpenMx <- function(object, plate_index = "i = 1, ..., N") {
  .umg_require("OpenMx", "umg_from_OpenMx")
  A <- object$A; S <- object$S
  if (is.null(A) || is.null(S))
    stop("Model does not contain RAM matrices 'A' and 'S'; ",
         "umg_from_OpenMx() requires a type = \"RAM\" model.",
         call. = FALSE)
  Av <- A$values; Af <- A$free
  Sv <- S$values; Sf <- S$free
  vars <- rownames(Av)
  if (is.null(vars)) vars <- colnames(Av)
  manifest <- object$manifestVars
  latent <- object$latentVars
  if (is.null(vars)) vars <- c(manifest, latent)

  nodes <- lapply(vars, function(v)
    umg_node(v, .umg_default_label(v),
             observed = v %in% manifest,
             dist = if (!(v %in% manifest)) "N(0, psi)" else NULL))
  names(nodes) <- vars

  edges <- list()
  for (i in seq_along(vars))
    for (j in seq_along(vars))
      if (i != j && (Av[i, j] != 0 || isTRUE(Af[i, j]))) {
        # RAM: A[i, j] is the path from vars[j] to vars[i]
        fixed <- if (!isTRUE(Af[i, j])) Av[i, j] else NULL
        edges <- c(edges, list(umg_edge(vars[j], vars[i], "dep",
                                        fixed = fixed)))
      }
  for (i in seq_along(vars))
    for (j in seq_along(vars))
      if (i < j && (Sv[i, j] != 0 || isTRUE(Sf[i, j])))
        edges <- c(edges, list(umg_edge(vars[i], vars[j], "cov")))

  # sources without an unconditional distribution get a free annotation
  has_in <- unique(vapply(Filter(function(e) e$kind == "dep", edges),
                          `[[`, character(1), "to"))
  for (v in vars)
    if (nodes[[v]]$observed && !(v %in% has_in))
      nodes[[v]]$dist <- "free"

  plates <- list(umg_plate("person", vars, plate_index))
  umg_model(unname(nodes), edges, plates)
}

#' Build a UMG from a qgraph object or weighted adjacency matrix
#'
#' Translates a network-psychometric object into a Gaussian-graphical
#' UMG. A \pkg{qgraph} object is reduced to its weights matrix; a plain
#' numeric matrix is treated directly as a (partial) association
#' matrix. Nonzero off-diagonal entries become symmetric `cov` edges
#' among observed continuous vertices. As the article notes, the UMG
#' displays an estimated network but does not by itself specify it,
#' since the structure is a picture of fitted quantities.
#'
#' @param object A `qgraph` object, or a square numeric weights matrix.
#' @param threshold Absolute-value cutoff below which an edge is
#'   omitted (default `0`, i.e. keep every nonzero entry).
#' @param plate_index Index label for the person plate.
#' @return An object of class `umg`.
#' @export
umg_from_qgraph <- function(object, threshold = 0,
                            plate_index = "i = 1, ..., N") {
  W <- NULL
  if (inherits(object, "qgraph")) {
    .umg_require("qgraph", "umg_from_qgraph")
    W <- tryCatch(qgraph::getWmat(object), error = function(e) NULL)
    if (is.null(W)) W <- object$Arguments$input
  } else if (is.matrix(object) || is.data.frame(object)) {
    W <- as.matrix(object)
  }
  if (is.null(W) || nrow(W) != ncol(W))
    stop("umg_from_qgraph() needs a qgraph object or a square ",
         "weights matrix.", call. = FALSE)
  p <- nrow(W)
  vars <- rownames(W)
  if (is.null(vars)) vars <- paste0("x", seq_len(p))
  Wa <- abs(W)
  if (max(abs(Wa - t(Wa))) > 1e-8) {
    warning("umg_from_qgraph(): asymmetric weights matrix (a directed ",
            "network); symmetrised by the elementwise maximum of ",
            "|w_ab| and |w_ba| before drawing, since UMG covariance ",
            "edges are undirected.", call. = FALSE)
    Wa <- pmax(Wa, t(Wa))
  }
  adj <- (Wa > threshold)
  diag(adj) <- FALSE
  umg_network(vars, edges_mat = adj * 1, plate_index = plate_index)
}
