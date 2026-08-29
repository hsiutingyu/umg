# ============================================================
# Title:  Additional motif constructors (V03 expansion)
# File:   motifs_extra.R (package umg)
# Author: H.-T. Yu
# Date:   2026-06-19
# ============================================================
# Builders for the model families named in the accompanying article
# but not covered by the original eight motifs: second-order and
# bifactor variants, exploratory SEM, formative/MIMIC measurement,
# a general SEM assembler, the random-intercept cross-lagged panel
# model, and the diagnostic classification model. Every builder
# returns a `umg` object that passes umg_validate() by construction.

#' General structural equation model builder
#'
#' Assembles a complete SEM from a measurement specification and an
#' optional structural specification, the flexible route when no
#' single-purpose motif fits. Factors named in `measurement` become
#' latent continuous vertices; their indicators become observed
#' continuous vertices with the first loading fixed to one for
#' scaling (unless `scaling = "variance"`). Structural regressions and
#' covariances are added as `dep` and `cov` edges respectively.
#'
#' @param measurement Named list mapping each latent factor name to a
#'   character vector of its indicator names.
#' @param structural Optional list of length-2 character vectors
#'   `c(from, to)` giving directed regressions among factors and/or
#'   observed variables.
#' @param covariances Optional list of length-2 character vectors
#'   giving symmetric covariance edges.
#' @param scaling `"marker"` (fix first loading to 1, the default) or
#'   `"variance"` (fix the factor variance to 1; no marker loading).
#'   Under variance scaling, exogenous factors are annotated
#'   `N(0, 1)` and endogenous factors carry a fixed unit *residual*
#'   variance (`resid var = 1`), matching the convention of
#'   `lavaan`'s `std.lv = TRUE`, so every factor's scale is fixed.
#' @param observed Optional character vector of additional observed
#'   variables referenced only in `structural`/`covariances`.
#' @param badge `"statistical"` (default) or `"structural"`.
#' @param plate_index Index label for the person plate.
#' @return An object of class `umg`.
#' @examples
#' m <- umg_sem(
#'   measurement = list(F1 = c("y1", "y2", "y3"),
#'                      F2 = c("y4", "y5", "y6")),
#'   structural  = list(c("F1", "F2"))
#' )
#' plot(m)
#' @export
umg_sem <- function(measurement,
                    structural = list(),
                    covariances = list(),
                    scaling = c("marker", "variance"),
                    observed = character(0),
                    badge = c("statistical", "structural"),
                    plate_index = "i = 1, ..., N") {
  scaling <- match.arg(scaling)
  badge <- match.arg(badge)
  stopifnot(is.list(measurement), length(measurement) >= 1L,
            !is.null(names(measurement)))
  factors <- names(measurement)

  # Which factors are endogenous (have a structural parent)?
  endo <- unique(vapply(structural, `[[`, character(1), 2L))

  nodes <- list()
  for (f in factors) {
    src <- !(f %in% endo)
    dist <- if (src) {
      if (scaling == "variance") "N(0, 1)" else "N(0, psi)"
    } else {
      # endogenous factors have no unconditional distribution, but
      # under variance scaling their residual variance is fixed to 1
      # (lavaan std.lv = TRUE); without that annotation the factor's
      # scale would be fixed by nothing.
      if (scaling == "variance") "resid var = 1" else NULL
    }
    nodes[[f]] <- umg_node(f, .umg_default_label(f), observed = FALSE,
                           dist = dist)
  }
  all_ind <- unique(unlist(measurement))
  for (v in all_ind)
    if (is.null(nodes[[v]]))
      nodes[[v]] <- umg_node(v, .umg_default_label(v), observed = TRUE)
  for (v in observed)
    if (is.null(nodes[[v]]))
      nodes[[v]] <- umg_node(v, .umg_default_label(v), observed = TRUE,
                             dist = "free")

  edges <- list()
  for (f in factors) {
    ind <- measurement[[f]]
    for (k in seq_along(ind)) {
      if (scaling == "marker" && k == 1L)
        edges <- c(edges, list(umg_edge(f, ind[k], "dep", fixed = 1)))
      else
        edges <- c(edges, list(umg_edge(f, ind[k], "dep",
                   label = paste0("$\\lambda_{", f, k, "}$"))))
    }
  }
  for (s in structural)
    edges <- c(edges, list(umg_edge(s[[1]], s[[2]], "dep")))
  for (cv in covariances)
    edges <- c(edges, list(umg_edge(cv[[1]], cv[[2]], "cov")))

  members <- unique(c(factors, all_ind, observed))
  plates <- list(umg_plate("person", members, plate_index))
  umg_model(unname(nodes), edges, plates, badge = badge)
}

#' Second-order factor motif
#'
#' Builds a hierarchical factor model: a single second-order factor
#' with directed paths to several first-order factors, each of which
#' loads on a block of observed indicators. The second-order factor
#' explains the covariation among the first-order factors.
#'
#' @param groups Named list mapping each first-order factor name to its
#'   indicator names.
#' @param general Name of the second-order factor.
#' @param plate_index Index label for the person plate.
#' @return An object of class `umg`.
#' @examples
#' plot(umg_secondorder(list(F1 = paste0("y", 1:3),
#'                           F2 = paste0("y", 4:6),
#'                           F3 = paste0("y", 7:9))))
#' @export
umg_secondorder <- function(groups,
                            general = "g",
                            plate_index = "i = 1, ..., N") {
  stopifnot(is.list(groups), length(groups) >= 2L, !is.null(names(groups)))
  fnames <- names(groups)
  # marker scaling throughout: the first second-order loading is fixed
  # to 1 and the general factor's variance stays free. Fixing both the
  # variance and a loading would over-restrict the model rather than
  # merely set its scale.
  nodes <- list(umg_node(general, .umg_default_label(general),
                         observed = FALSE, dist = "N(0, psi_g)"))
  for (f in fnames)
    nodes[[length(nodes) + 1L]] <-
      umg_node(f, .umg_default_label(f), observed = FALSE)  # endogenous
  for (v in unique(unlist(groups)))
    nodes[[length(nodes) + 1L]] <-
      umg_node(v, .umg_default_label(v), observed = TRUE)

  edges <- list()
  for (j in seq_along(fnames))
    edges <- c(edges, list(umg_edge(general, fnames[j], "dep",
               fixed = if (j == 1L) 1 else NULL,
               label = if (j == 1L) "" else paste0("$\\gamma_{", j, "}$"))))
  for (f in fnames) {
    ind <- groups[[f]]
    for (k in seq_along(ind))
      edges <- c(edges, list(umg_edge(f, ind[k], "dep",
                 fixed = if (k == 1L) 1 else NULL)))
  }
  members <- c(general, fnames, unique(unlist(groups)))
  umg_model(nodes, edges, list(umg_plate("person", members, plate_index)))
}

#' Exploratory structural equation model motif
#'
#' Builds an ESEM measurement block in which every factor loads on
#' every indicator, the defining feature that distinguishes ESEM from
#' the zero cross-loadings of confirmatory factor analysis. Factor
#' variances are fixed to one for scaling, as rotation determines the
#' loading pattern.
#'
#' @param factors Character vector of factor names.
#' @param indicators Character vector of indicator names.
#' @param plate_index Index label for the person plate.
#' @return An object of class `umg`.
#' @examples
#' plot(umg_esem(c("F1", "F2"), paste0("y", 1:6)))
#' @export
umg_esem <- function(factors = c("F1", "F2"),
                     indicators = paste0("y", 1:6),
                     plate_index = "i = 1, ..., N") {
  stopifnot(length(factors) >= 1L, length(indicators) >= length(factors))
  nodes <- c(
    lapply(factors, function(f)
      umg_node(f, .umg_default_label(f), observed = FALSE,
               dist = "N(0, 1)")),
    lapply(indicators, function(v)
      umg_node(v, .umg_default_label(v), observed = TRUE))
  )
  edges <- list()
  for (f in factors)
    for (v in indicators)
      edges <- c(edges, list(umg_edge(f, v, "dep")))
  # free factor covariances
  if (length(factors) >= 2L)
    for (a in seq_along(factors))
      for (b in seq_along(factors))
        if (a < b)
          edges <- c(edges, list(umg_edge(factors[a], factors[b], "cov")))
  members <- c(factors, indicators)
  umg_model(nodes, edges, list(umg_plate("person", members, plate_index)))
}

#' Formative (composite) measurement motif
#'
#' Builds a formative measurement model in which observed indicators
#' are causes of a composite latent variable, the reverse of the
#' reflective direction. Because a composite is identified only when it
#' emits to at least two further quantities, an optional pair of
#' reflective outcome indicators may be supplied. The scale of the
#' composite is fixed by default by fixing the weight of the first
#' indicator to 1 (the marker convention lavaan applies to `<~`
#' composites), so that the motif passes [umg_check_scaling()].
#'
#' @param indicators Character vector of formative indicator (cause)
#'   names.
#' @param composite Name of the composite latent variable.
#' @param outcomes Optional character vector of reflective outcome
#'   indicators emitted by the composite (recommended for
#'   identification, typically >= 2).
#' @param scaling `"marker"` (the default) fixes the weight of the
#'   first indicator to 1; `"none"` leaves every weight free, which
#'   draws the composite without a scaling mark (it is then reported as
#'   unscaled by [umg_check_scaling()]).
#' @param plate_index Index label for the person plate.
#' @return An object of class `umg`.
#' @examples
#' plot(umg_formative(paste0("x", 1:4), outcomes = c("y1", "y2")))
#' @export
umg_formative <- function(indicators = paste0("x", 1:4),
                          composite = "C",
                          outcomes = NULL,
                          scaling = c("marker", "none"),
                          plate_index = "i = 1, ..., N") {
  scaling <- match.arg(scaling)
  stopifnot(length(indicators) >= 2L)
  nodes <- c(
    lapply(indicators, function(v)
      umg_node(v, .umg_default_label(v), observed = TRUE, dist = "free")),
    list(umg_node(composite, .umg_default_label(composite),
                  observed = FALSE, dist = "N(0, zeta)"))
  )
  # the first weight is the marker that fixes the composite's scale
  edges <- lapply(seq_along(indicators), function(k) {
    v <- indicators[k]
    if (scaling == "marker" && k == 1L)
      umg_edge(v, composite, "dep", fixed = 1)
    else
      umg_edge(v, composite, "dep", label = paste0("$w_{", v, "}$"))
  })
  members <- c(indicators, composite)
  if (!is.null(outcomes)) {
    for (y in outcomes) {
      nodes <- c(nodes, list(umg_node(y, .umg_default_label(y),
                                      observed = TRUE)))
      edges <- c(edges, list(umg_edge(composite, y, "dep")))
    }
    members <- c(members, outcomes)
  }
  umg_model(nodes, edges, list(umg_plate("person", members, plate_index)))
}

#' MIMIC (multiple-indicator multiple-cause) motif
#'
#' Builds a MIMIC model: observed covariates predict a reflective
#' latent factor that in turn loads on observed indicators. The cause
#' side is formative and the effect side is reflective, a structure
#' widely used to model the effect of background variables on a latent
#' trait and to probe differential item functioning.
#'
#' @param causes Character vector of observed predictor names.
#' @param indicators Character vector of reflective indicator names.
#' @param factor Name of the latent factor.
#' @param plate_index Index label for the person plate.
#' @return An object of class `umg`.
#' @examples
#' plot(umg_mimic(c("age", "sex"), paste0("y", 1:4)))
#' @export
umg_mimic <- function(causes = c("z1", "z2"),
                      indicators = paste0("y", 1:4),
                      factor = "F",
                      plate_index = "i = 1, ..., N") {
  stopifnot(length(causes) >= 1L, length(indicators) >= 2L)
  nodes <- c(
    lapply(causes, function(v)
      umg_node(v, .umg_default_label(v), observed = TRUE, dist = "free")),
    list(umg_node(factor, .umg_default_label(factor), observed = FALSE,
                  dist = "N(0, psi)")),
    lapply(indicators, function(v)
      umg_node(v, .umg_default_label(v), observed = TRUE))
  )
  edges <- lapply(causes, function(v)
    umg_edge(v, factor, "dep", label = paste0("$\\gamma_{", v, "}$")))
  for (k in seq_along(indicators))
    edges <- c(edges, list(umg_edge(factor, indicators[k], "dep",
               fixed = if (k == 1L) 1 else NULL)))
  members <- c(causes, factor, indicators)
  umg_model(nodes, edges, list(umg_plate("person", members, plate_index)))
}

#' Random-intercept cross-lagged panel model (RI-CLPM) motif
#'
#' Builds the random-intercept cross-lagged panel model of
#' Hamaker, Kuiper, and Grasman (2015) for two constructs measured over
#' several waves. Stable between-person differences are absorbed by two
#' random-intercept factors, while autoregressive and cross-lagged
#' paths operate on the within-person components, the decomposition
#' that distinguishes the RI-CLPM from the traditional cross-lagged
#' panel model.
#'
#' @param waves Number of measurement occasions (>= 2).
#' @param x,y Stems for the two observed construct names.
#' @param plate_index Index label for the person plate.
#' @return An object of class `umg`.
#' @examples
#' plot(umg_riclpm(waves = 4))
#' @export
umg_riclpm <- function(waves = 4,
                       x = "x", y = "y",
                       plate_index = "i = 1, ..., N") {
  stopifnot(waves >= 2L)
  Tn <- seq_len(waves)
  ox <- paste0(x, Tn); oy <- paste0(y, Tn)
  wx <- paste0("w", x, Tn); wy <- paste0("w", y, Tn)

  nodes <- list(
    umg_node("RIx", paste0("$RI_{", x, "}$"), observed = FALSE,
             dist = "N(0, psi_x)"),
    umg_node("RIy", paste0("$RI_{", y, "}$"), observed = FALSE,
             dist = "N(0, psi_y)")
  )
  for (t in Tn) {
    # within-person components: sources at t = 1 carry a distribution.
    # The decomposition x_t = RI_x + w_xt is exact, so the observed
    # vertices carry no residual of their own (var = 0).
    src1 <- t == 1L
    nodes <- c(nodes,
      list(umg_node(wx[t], paste0("$", x, "^{*}_{", t, "i}$"),
                    observed = FALSE,
                    dist = if (src1) "N(0, sigma_x)" else NULL),
           umg_node(wy[t], paste0("$", y, "^{*}_{", t, "i}$"),
                    observed = FALSE,
                    dist = if (src1) "N(0, sigma_y)" else NULL),
           umg_node(ox[t], paste0("$", x, "_{", t, "i}$"),
                    observed = TRUE, dist = "var = 0"),
           umg_node(oy[t], paste0("$", y, "_{", t, "i}$"),
                    observed = TRUE, dist = "var = 0")))
  }

  edges <- list()
  for (t in Tn) {
    edges <- c(edges,
      list(umg_edge("RIx", ox[t], "dep", fixed = 1),
           umg_edge("RIy", oy[t], "dep", fixed = 1),
           umg_edge(wx[t], ox[t], "dep", fixed = 1),
           umg_edge(wy[t], oy[t], "dep", fixed = 1)))
  }
  # lagged paths are wave-indexed: the RI-CLPM does not constrain the
  # autoregressive and cross-lagged coefficients to be equal across
  # transitions unless the analyst imposes stationarity.
  for (t in Tn[-1]) {
    edges <- c(edges,
      list(umg_edge(wx[t - 1], wx[t], "dep",
                    label = paste0("$\\alpha_{", t - 1, "}$")),
           umg_edge(wy[t - 1], wy[t], "dep",
                    label = paste0("$\\delta_{", t - 1, "}$")),
           umg_edge(wx[t - 1], wy[t], "dep",
                    label = paste0("$\\beta_{", t - 1, "}$")),
           umg_edge(wy[t - 1], wx[t], "dep",
                    label = paste0("$\\gamma_{", t - 1, "}$"))))
  }
  # within-wave association: initial-state covariance at t = 1 and a
  # wave-specific innovation covariance at every later wave (Hamaker,
  # Kuiper, & Grasman, 2015)
  edges <- c(edges,
    list(umg_edge("RIx", "RIy", "cov", label = "$\\psi_{xy}$"),
         umg_edge(wx[1], wy[1], "cov", label = "$\\sigma_{xy1}$")))
  for (t in Tn[-1]) {
    edges <- c(edges,
      list(umg_edge(wx[t], wy[t], "cov",
                    label = paste0("$\\sigma_{xy", t, "}$"))))
  }

  members <- c("RIx", "RIy", wx, wy, ox, oy)
  umg_model(nodes, edges, list(umg_plate("person", members, plate_index)))
}

#' Diagnostic classification model (DCM) motif
#'
#' Builds a diagnostic classification (cognitive diagnosis) model:
#' several binary latent attributes (latent categorical vertices)
#' govern, through a Q-matrix, the observed item responses at the
#' crossing of person and item plates. Item parameters are fixed
#' unknowns in the item plate. This combines a latent categorical
#' structure with the crossed-plate measurement form, a structure no
#' single classic convention can draw.
#'
#' @param Q A K-by-J 0/1 Q-matrix: rows are attributes, columns are
#'   items; `Q[k, j] = 1` if item `j` requires attribute `k`. Note
#'   that this is the transpose of the J-by-K (items-by-attributes)
#'   layout used by, for example, the GDINA and CDM packages; a
#'   warning is issued when the supplied matrix has at least as many
#'   rows as columns, the usual sign of the transposed convention.
#'   Because the diagram shows the generic response vertex `u_ij`
#'   rather than per-item vertices, the Q-matrix is collapsed to the
#'   attribute level: attribute `k` points at `u` when at least one
#'   item requires it. Defaults to a 3-attribute, 6-item example.
#' @param attr_cov Logical; draw pairwise covariance edges among the
#'   latent attributes (default `TRUE`), reflecting the saturated (or
#'   higher-order) attribute distribution that standard DCMs assume.
#'   Set to `FALSE` to draw independent attributes.
#' @param plate_index Index label for the person plate.
#' @return An object of class `umg`.
#' @examples
#' Q <- rbind(c(1,1,0,0,1,0), c(0,1,1,0,0,1), c(0,0,1,1,1,1))
#' plot(umg_dcm(Q))
#' @export
umg_dcm <- function(Q = NULL, attr_cov = TRUE,
                    plate_index = "i = 1, ..., N") {
  if (is.null(Q))
    Q <- rbind(c(1, 1, 0, 0, 1, 0),
               c(0, 1, 1, 0, 0, 1),
               c(0, 0, 1, 1, 1, 1))
  Q <- as.matrix(Q)
  if (nrow(Q) >= ncol(Q))
    warning("umg_dcm(): Q has at least as many rows as columns; ",
            "umg_dcm() expects attributes in rows and items in ",
            "columns (K x J). If your Q-matrix is items-by-attributes ",
            "(the GDINA/CDM convention), pass t(Q).", call. = FALSE)
  K <- nrow(Q)
  attrs <- paste0("alpha", seq_len(K))

  nodes <- c(
    lapply(seq_len(K), function(k)
      umg_node(attrs[k], paste0("$\\alpha_{", k, "i}$"), observed = FALSE,
               support = "categorical", dist = "Bernoulli(p_k)")),
    list(umg_node("u", "$u_{ij}$", observed = TRUE,
                  support = "categorical", dist = "Bernoulli(p_ij)"),
         umg_node("delta", "$\\delta_j$", role = "par"))
  )
  # an item requires attribute k if any column j has Q[k, j] = 1
  edges <- list(umg_edge("delta", "u", "dep"))
  for (k in seq_len(K))
    if (any(Q[k, ] != 0))
      edges <- c(edges, list(umg_edge(attrs[k], "u", "dep")))
  if (attr_cov && K >= 2L)
    for (a in seq_len(K))
      for (b in seq_len(K))
        if (a < b)
          edges <- c(edges, list(umg_edge(attrs[a], attrs[b], "cov")))

  plates <- list(
    umg_plate("person", c(attrs, "u"), plate_index),
    umg_plate("item", c("u", "delta"), "j = 1, ..., J")
  )
  umg_model(nodes, edges, plates)
}
