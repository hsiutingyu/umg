# ============================================================
# Title:  High-level motif constructors for common model families
# File:   motifs.R (package umg)
# Author: H.-T. Yu
# Date:   2026-06-18
# ============================================================
# Convenience builders that assemble complete, well-formed UMG
# objects for the model families psychologists draw most often, so
# that an applied researcher can obtain a publication-ready diagram
# from a one-line specification and then edit the returned object.
# Each builder returns an object of class `umg`; all pass
# umg_validate() by construction.

#' Reflective factor (measurement) motif
#'
#' Builds a single-factor reflective measurement model: one latent
#' continuous factor with directed loadings onto observed continuous
#' indicators, the first loading fixed to 1 for scaling, residual
#' variances implied, and a person plate.
#'
#' @param factor Name of the latent factor (character scalar).
#' @param indicators Character vector of indicator names (>= 2).
#' @param loadings Optional character vector of loading labels for the
#'   free loadings (the indicators after the first), so of length
#'   `length(indicators) - 1`. A vector of length `length(indicators)`
#'   is also accepted, in which case its first element (the fixed
#'   marker loading) is ignored. Defaults to `lambda[k]`.
#' @param factor_label,indicator_labels Optional display labels.
#' @param plate_index Index label for the person plate.
#' @param dist Distribution annotation for the factor (source vertex).
#' @return An object of class `umg`.
#' @examples
#' m <- umg_factor("F", c("y1", "y2", "y3"))
#' plot(m)
#' @export
umg_factor <- function(factor = "F",
                       indicators = c("y1", "y2", "y3"),
                       loadings = NULL,
                       factor_label = NULL,
                       indicator_labels = NULL,
                       plate_index = "i = 1, ..., N",
                       dist = "N(0, psi)") {
  stopifnot(length(indicators) >= 2L)
  K <- length(indicators)
  if (is.null(factor_label))
    factor_label <- paste0("$", factor, "_i$")
  if (is.null(indicator_labels))
    indicator_labels <- paste0("$", indicators, "_i$")
  if (is.null(loadings)) {
    loadings <- paste0("$\\lambda_{", 2:K, "}$")
  } else if (length(loadings) == K) {
    loadings <- loadings[-1L]   # tolerate a full-length vector
  } else if (length(loadings) != K - 1L) {
    stop("'loadings' must have length ", K - 1L,
         " (one label per free loading) or ", K, ".", call. = FALSE)
  }

  nodes <- c(
    list(umg_node(factor, factor_label, observed = FALSE, dist = dist)),
    Map(function(nm, lab) umg_node(nm, lab, observed = TRUE),
        indicators, indicator_labels)
  )
  edges <- vector("list", length(indicators))
  for (k in seq_along(indicators)) {
    edges[[k]] <- if (k == 1L)
      umg_edge(factor, indicators[k], "dep", fixed = 1)
    else
      umg_edge(factor, indicators[k], "dep", label = loadings[k - 1L])
  }
  plates <- list(umg_plate("person", c(factor, indicators), plate_index))
  umg_model(nodes, edges, plates)
}

#' Bifactor measurement motif
#'
#' Builds a bifactor model: a general factor loading on every
#' indicator plus one or more orthogonal group factors each loading on
#' a contiguous block of indicators. This is the representation behind
#' the general factor of psychopathology and similar structures.
#'
#' @param indicators Character vector of all indicator names.
#' @param groups A list of character vectors; each element names the
#'   indicators loading on one group factor.
#' @param general Name of the general factor.
#' @param plate_index Index label for the person plate.
#' @return An object of class `umg`.
#' @examples
#' umg_bifactor(paste0("y", 1:6),
#'              groups = list(g1 = paste0("y", 1:3),
#'                            g2 = paste0("y", 4:6)))
#' @export
umg_bifactor <- function(indicators,
                         groups,
                         general = "g",
                         plate_index = "i = 1, ..., N") {
  stopifnot(is.list(groups), length(groups) >= 1L)
  gnames <- names(groups)
  if (is.null(gnames)) gnames <- paste0("f", seq_along(groups))

  nodes <- c(
    list(umg_node(general, paste0("$g_i$"), observed = FALSE,
                  dist = "N(0, 1)")),
    lapply(seq_along(groups), function(j)
      umg_node(gnames[j], paste0("$f_{", j, "i}$"), observed = FALSE,
               dist = "N(0, 1)")),
    lapply(indicators, function(nm)
      umg_node(nm, paste0("$", nm, "_i$"), observed = TRUE))
  )
  edges <- list()
  for (nm in indicators)
    edges <- c(edges, list(umg_edge(general, nm, "dep")))
  for (j in seq_along(groups))
    for (nm in groups[[j]])
      edges <- c(edges, list(umg_edge(gnames[j], nm, "dep")))

  plates <- list(umg_plate("person",
                           c(general, gnames, indicators), plate_index))
  umg_model(nodes, edges, plates)
}

#' Latent growth-curve motif
#'
#' Builds a latent growth model: a latent intercept factor and a
#' latent slope factor over a set of manifest repeated measures, with
#' fixed unit loadings from the intercept and fixed time-score
#' loadings from the slope, and an intercept--slope covariance.
#'
#' @param occasions Number of repeated measures (>= 3).
#' @param times Optional numeric time scores (defaults to 0, 1, ...,
#'   `occasions - 1`).
#' @param outcome Stem for the manifest outcome names (e.g. `"y"`).
#' @param plate_index Index label for the person plate.
#' @return An object of class `umg`.
#' @examples
#' plot(umg_growth(4))
#' @export
umg_growth <- function(occasions = 4,
                       times = NULL,
                       outcome = "y",
                       plate_index = "i = 1, ..., N") {
  stopifnot(occasions >= 3L)
  if (is.null(times)) times <- seq_len(occasions) - 1
  if (length(times) != occasions)
    stop("'times' must have length 'occasions' (", occasions, ").",
         call. = FALSE)
  ys <- paste0(outcome, seq_len(occasions))

  nodes <- c(
    list(umg_node("I", "$\\alpha_i$", observed = FALSE,
                  dist = "N(mu_I, psi_I)"),
         umg_node("S", "$\\beta_i$", observed = FALSE,
                  dist = "N(mu_S, psi_S)")),
    lapply(seq_along(ys), function(t)
      umg_node(ys[t], paste0("$", outcome, "_{", t, "i}$"),
               observed = TRUE))
  )
  edges <- list()
  for (t in seq_along(ys)) {
    edges <- c(edges,
               list(umg_edge("I", ys[t], "dep", fixed = 1)),
               list(umg_edge("S", ys[t], "dep", fixed = times[t])))
  }
  edges <- c(edges, list(umg_edge("I", "S", "cov",
                                  label = "$\\psi_{IS}$")))
  plates <- list(umg_plate("person", c("I", "S", ys), plate_index))
  umg_model(nodes, edges, plates)
}

#' Mediation motif
#'
#' Builds an X -> M -> Y mediation diagram with an optional direct
#' effect and an optional latent confounder of the mediator and the
#' outcome. The interpretive badge controls whether the diagram
#' licenses a causal reading.
#'
#' @param x,m,y Names of the predictor, mediator, and outcome.
#' @param direct Logical; include the direct X -> Y path (default
#'   `TRUE`).
#' @param confounder Logical; include a latent confounder U of M and Y
#'   (default `FALSE`).
#' @param badge `"statistical"` or `"structural"`.
#' @param plate_index Index label for the person plate.
#' @return An object of class `umg`.
#' @examples
#' plot(umg_mediation(confounder = TRUE, badge = "structural"))
#' @export
umg_mediation <- function(x = "X", m = "M", y = "Y",
                          direct = TRUE, confounder = FALSE,
                          badge = c("statistical", "structural"),
                          plate_index = "i = 1, ..., N") {
  badge <- match.arg(badge)
  nodes <- list(
    umg_node(x, paste0("$", x, "_i$"), observed = TRUE, dist = "free"),
    umg_node(m, paste0("$", m, "_i$"), observed = TRUE),
    umg_node(y, paste0("$", y, "_i$"), observed = TRUE)
  )
  edges <- list(
    umg_edge(x, m, "dep", label = "$a$"),
    umg_edge(m, y, "dep", label = "$b$")
  )
  if (direct) edges <- c(edges, list(umg_edge(x, y, "dep",
                                              label = "$c'$")))
  members <- c(x, m, y)
  if (confounder) {
    nodes <- c(nodes, list(umg_node("U", "$u_i$", observed = FALSE,
                                    dist = "N(0, 1)")))
    edges <- c(edges, list(umg_edge("U", m, "dep"),
                           umg_edge("U", y, "dep")))
    members <- c(members, "U")
  }
  plates <- list(umg_plate("person", members, plate_index))
  umg_model(nodes, edges, plates, badge = badge)
}

#' Latent class motif
#'
#' Builds a latent class (or latent profile) model: a latent
#' categorical class vertex with mixing proportions, predicting a set
#' of observed indicators. Categorical indicators yield latent class
#' analysis; continuous indicators yield a latent profile model.
#'
#' @param indicators Character vector of indicator names.
#' @param categorical Logical; `TRUE` (default) for categorical
#'   indicators (LCA), `FALSE` for continuous (LPA).
#' @param class Name of the latent class vertex.
#' @param plate_index Index label for the person plate.
#' @return An object of class `umg`.
#' @examples
#' plot(umg_lca(paste0("u", 1:4)))
#' @export
umg_lca <- function(indicators = paste0("u", 1:4),
                    categorical = TRUE,
                    class = "c",
                    plate_index = "i = 1, ..., N") {
  nodes <- c(
    list(umg_node("pi", "$\\pi$", role = "par"),
         umg_node(class, "$c_i$", observed = FALSE,
                  support = "categorical", dist = "Categorical(pi)")),
    lapply(indicators, function(nm)
      umg_node(nm, paste0("$", nm, "_i$"), observed = TRUE,
               support = if (categorical) "categorical" else "continuous"))
  )
  edges <- c(list(umg_edge("pi", class, "dep")),
             lapply(indicators, function(nm)
               umg_edge(class, nm, "dep")))
  plates <- list(umg_plate("person", c(class, indicators), plate_index))
  umg_model(nodes, edges, plates)
}

#' Item response theory motif (crossed persons x items)
#'
#' Builds a unidimensional IRT diagram with crossed person and item
#' plates: a latent ability in the person plate, item parameters as
#' fixed unknowns in the item plate, and an observed categorical
#' response at the crossing.
#'
#' @param model Item model. Dichotomous: `"1PL"`, `"2PL"`, `"3PL"`.
#'   Polytomous: `"graded"` (graded response model, GRM), `"PCM"`
#'   (partial credit model), `"GPCM"` (generalized partial credit
#'   model). The choice controls which item-parameter diamonds are
#'   drawn (discrimination, difficulty/thresholds, guessing).
#' @param ability Name/label stem for the latent ability.
#' @param n_dim Number of latent ability dimensions (>= 1). With more
#'   than one dimension the model is multidimensional IRT (MIRT); each
#'   ability vertex points at the response.
#' @return An object of class `umg`.
#' @examples
#' plot(umg_irt("2PL"))
#' plot(umg_irt("graded"))
#' plot(umg_irt("2PL", n_dim = 2))
#' @export
umg_irt <- function(model = c("2PL", "1PL", "3PL",
                              "graded", "PCM", "GPCM"),
                    ability = "theta",
                    n_dim = 1L) {
  model <- match.arg(model)
  n_dim <- as.integer(n_dim)
  stopifnot(n_dim >= 1L)

  polytomous <- model %in% c("graded", "PCM", "GPCM")
  has_a <- model %in% c("2PL", "3PL", "graded", "GPCM")
  has_g <- model == "3PL"

  # ----- latent ability dimension(s) -----------------------------
  ability_nodes <- lapply(seq_len(n_dim), function(d) {
    nm  <- if (n_dim == 1L) ability else paste0(ability, d)
    lab <- if (n_dim == 1L) "$\\theta_i$" else paste0("$\\theta_{", d, "i}$")
    umg_node(nm, lab, observed = FALSE, dist = "N(0, 1)")
  })
  ability_names <- vapply(ability_nodes, `[[`, character(1), "name")

  # ----- observed response and item parameters -------------------
  resp_dist <- if (model == "graded") "Ordered(p_ij)"
               else if (polytomous) "Categorical(p_ij)"
               else "Bernoulli(p_ij)"
  b_lab <- if (polytomous) "$b_{jk}$" else "$b_j$"

  nodes <- c(
    ability_nodes,
    list(umg_node("u", "$u_{ij}$", observed = TRUE,
                  support = "categorical", dist = resp_dist),
         umg_node("b", b_lab, role = "par"))
  )
  edges <- c(lapply(ability_names, function(a) umg_edge(a, "u", "dep")),
             list(umg_edge("b", "u", "dep")))
  item_members <- c("u", "b")
  if (has_a) {
    nodes <- c(nodes, list(umg_node("a", "$a_j$", role = "par")))
    edges <- c(edges, list(umg_edge("a", "u", "dep")))
    item_members <- c(item_members, "a")
  }
  if (has_g) {
    nodes <- c(nodes, list(umg_node("g", "$g_j$", role = "par")))
    edges <- c(edges, list(umg_edge("g", "u", "dep")))
    item_members <- c(item_members, "g")
  }

  plates <- list(
    umg_plate("person", c(ability_names, "u"), "i = 1, ..., N"),
    umg_plate("item", item_members, "j = 1, ..., J")
  )
  umg_model(nodes, edges, plates)
}

#' Add a finite-mixture wrapper to an existing UMG
#'
#' Promotes a set of parameter or latent vertices to class-varying
#' quantities by adding a latent class vertex with mixing edges into
#' them, implementing the mixture move described in the accompanying
#' article. The latent growth model of [umg_growth()] wrapped this way
#' becomes a growth mixture model.
#'
#' @param model An object of class `umg`.
#' @param targets Character vector of vertex names the class selects.
#' @param class Name of the latent class vertex to add.
#' @param plate Optional name of an existing plate to add the class
#'   vertex to (defaults to the first plate, typically the person
#'   plate).
#' @return An object of class `umg`.
#' @examples
#' g <- umg_growth(4)
#' umg_mixture(g, targets = c("I", "S"))
#' @export
umg_mixture <- function(model, targets, class = "c", plate = NULL) {
  stopifnot(inherits(model, "umg"))
  missing_t <- setdiff(targets, names(model$nodes))
  if (length(missing_t))
    stop("umg_mixture(): target vertex(es) not in model: ",
         paste(missing_t, collapse = ", "), call. = FALSE)
  nodes <- model$nodes
  nodes[["pi"]] <- umg_node("pi", "$\\pi$", role = "par")
  nodes[[class]] <- umg_node(class, "$c_i$", observed = FALSE,
                             support = "categorical",
                             dist = "Categorical(pi)")
  edges <- c(model$edges, list(umg_edge("pi", class, "dep")))
  for (tg in targets)
    edges <- c(edges, list(umg_edge(class, tg, "mix")))

  plates <- model$plates
  if (length(plates)) {
    j <- if (is.null(plate)) 1L else match(plate, vapply(
      plates, `[[`, character(1), "name"))
    if (is.na(j))
      stop("umg_mixture(): no plate named '", plate, "' in the model.",
           call. = FALSE)
    # the class indicator is person-level and joins the plate; the
    # mixing-proportion parameter pi is a population quantity and
    # stays outside (consistent with umg_lca())
    plates[[j]]$members <- unique(c(plates[[j]]$members, class))
  }
  umg_model(unname(nodes), edges, plates, badge = model$badge)
}

#' Undirected network (Gaussian graphical model) motif
#'
#' Builds a network-psychometric diagram: observed continuous
#' variables joined by symmetric covariance edges representing the
#' partial-association structure of a Gaussian graphical model.
#'
#' @param vars Character vector of observed variable names.
#' @param edges_mat Optional logical or numeric adjacency matrix
#'   selecting which pairs are connected; a pair is joined when either
#'   the upper- or the lower-triangular entry is nonzero, so upper-,
#'   lower-, and fully symmetric encodings are all accepted. Defaults
#'   to a fully connected graph.
#' @param plate_index Index label for the person plate.
#' @return An object of class `umg`.
#' @examples
#' plot(umg_network(paste0("x", 1:4)))
#' @export
umg_network <- function(vars = paste0("x", 1:5),
                        edges_mat = NULL,
                        plate_index = "i = 1, ..., N") {
  p <- length(vars)
  if (is.null(edges_mat)) {
    edges_mat <- matrix(1, p, p); diag(edges_mat) <- 0
  }
  stopifnot(nrow(edges_mat) == p, ncol(edges_mat) == p)
  nodes <- lapply(vars, function(nm)
    umg_node(nm, paste0("$", nm, "_i$"), observed = TRUE,
             dist = "free"))
  edges <- list()
  for (a in seq_len(p))
    for (b in seq_len(p))
      if (a < b && (edges_mat[a, b] != 0 || edges_mat[b, a] != 0))
        edges <- c(edges, list(umg_edge(vars[a], vars[b], "cov")))
  plates <- list(umg_plate("person", vars, plate_index))
  umg_model(nodes, edges, plates)
}
