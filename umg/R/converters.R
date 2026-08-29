# ============================================================
# Title:  Construct UMGs from fitted model objects
# File:   converters.R (package umg)
# Author: H.-T. Yu
# Date:   2026-06-12
# ============================================================

#' Build a UMG from a lavaan model
#'
#' Translates a lavaan parameter table into a UMG: latent variables
#' (`=~` left-hand sides) become latent continuous vertices, observed
#' indicators become observed continuous vertices, loadings and
#' regressions become `dep` edges, off-diagonal `~~` rows become
#' `cov` edges, and diagonal `~~` rows are carried as variance
#' annotations. Intercept and mean rows (`~1`) are carried as mean
#' annotations on the vertex (`mean = free`, `mean = 0`,
#' `mean = <value>`, or `mean = fixed` when lavaan fixes the mean at a
#' sample value, as for exogenous covariates under `fixed.x = TRUE`),
#' so that a model's mean structure survives the round trip through
#' [umg_to_lavaan()]. A single person plate is added over all random
#' vertices, making explicit the replication that classic SEM
#' diagrams leave implicit.
#'
#' @param object A fitted lavaan object, or a lavaan model syntax
#'   string (which is then lavaanified without fitting).
#' @param plate_index Index label for the person plate.
#' @param bayesian Logical; if `TRUE`, free parameters are rendered in
#'   their prior-closed (Bayesian) form. Defaults to `FALSE`. Used by
#'   [umg_from_blavaan()].
#' @return An object of class `umg`.
#' @export
umg_from_lavaan <- function(object, plate_index = "i = 1, ..., N",
                            bayesian = FALSE) {
  .umg_require("lavaan", "umg_from_lavaan")
  pt <- if (is.character(object)) {
    lavaan::lavaanify(object, auto = TRUE, model.type = "sem")
  } else {
    lavaan::parameterTable(object)
  }
  .umg_build_partable(pt, plate_index = plate_index, bayesian = bayesian)
}

# Internal: build a UMG from a lavaan-style parameter table. Shared by
# umg_from_lavaan() and umg_from_blavaan().
.umg_build_partable <- function(pt, plate_index = "i = 1, ..., N",
                                bayesian = FALSE) {
  # Multi-group fits repeat the whole parameter structure once per
  # group; drawing every group's copy would duplicate each edge. The
  # diagram describes the common structure, so only the first group's
  # rows are read (group 0 rows carry constraints, not structure).
  if ("group" %in% names(pt) && any(pt$group > 1L, na.rm = TRUE)) {
    message("umg_from_lavaan(): multi-group model; drawing the ",
            "common structure from the first group's parameter rows.")
    pt <- pt[is.na(pt$group) | pt$group <= 1L, , drop = FALSE]
  }

  supported <- c("=~", "~", "~~", "~1")
  ignorable <- c("|", ":=", "==", "<", ">", "~*~", "da")
  unsup <- setdiff(unique(pt$op), c(supported, ignorable))
  if (length(unsup))
    warning("umg_from_lavaan(): unsupported operator(s) skipped: ",
            paste(unsup, collapse = ", "), call. = FALSE)

  lv <- unique(pt$lhs[pt$op == "=~"])
  ov <- setdiff(unique(c(pt$rhs[pt$op == "=~"],
                         pt$lhs[pt$op == "~"], pt$rhs[pt$op == "~"])),
                lv)
  ordinal <- unique(pt$lhs[pt$op == "|"])   # variables with thresholds

  nodes <- list()
  for (v in lv)
    nodes[[v]] <- umg_node(v, paste0("$", v, "_i$"), observed = FALSE)
  for (v in ov)
    nodes[[v]] <- umg_node(v, paste0("$", v, "_i$"), observed = TRUE,
                           support = if (v %in% ordinal) "categorical"
                                     else "continuous")
  if (length(ordinal)) {
    for (v in intersect(ordinal, names(nodes))) {
      nk <- sum(pt$op == "|" & pt$lhs == v)
      nodes[[v]]$annot <- paste0(nk, " threshold",
                                 if (nk > 1L) "s" else "")
    }
    message("umg_from_lavaan(): ordinal indicator(s) ",
            paste(ordinal, collapse = ", "),
            " typed categorical; thresholds carried as annotations.")
  }

  # a fixed value for non-free rows: ustart when given, otherwise the
  # fitted value (fixed.x = TRUE fixes exogenous moments at sample
  # values, which live in 'est', not 'ustart')
  .fixed_val <- function(r) {
    if (pt$free[r] != 0L) return(NULL)
    v <- pt$ustart[r]
    if (is.na(v) && "est" %in% names(pt)) v <- round(pt$est[r], 2)
    if (is.na(v)) NULL else v
  }

  # mean structure: "~1" rows become "mean = ..." annotations. A row
  # fixed without a start value is fixed at a sample quantity (lavaan's
  # fixed.x = TRUE for exogenous covariates) and is recorded as
  # "mean = fixed"; umg_to_lavaan() emits no intercept line for it,
  # since a refit under fixed.x = TRUE fixes it the same way.
  .mean_val <- function(r) {
    if (pt$free[r] != 0L) return("free")
    v <- pt$ustart[r]
    if (is.na(v)) "fixed" else as.character(v)
  }

  edges <- list()
  k <- 0L
  for (r in seq_len(nrow(pt))) {
    op <- pt$op[r]; lhs <- pt$lhs[r]; rhs <- pt$rhs[r]
    if (!op %in% supported) next
    if (op == "~1") {
      if (!is.null(nodes[[lhs]]))
        nodes[[lhs]]$annot <- .umg_annot_add(
          nodes[[lhs]]$annot, paste0("mean = ", .mean_val(r)))
      next
    }
    if (is.null(nodes[[lhs]]) ||
        (op != "~~" && is.null(nodes[[rhs]])) ||
        (op == "~~" && lhs != rhs && is.null(nodes[[rhs]])))
      next  # endpoints introduced only by unsupported operators
    fixed <- .fixed_val(r)
    lab <- if (pt$free[r] != 0L) {
      if (nzchar(pt$label[r])) pt$label[r] else ""
    } else ""
    k <- k + 1L
    if (op == "=~") {
      edges[[k]] <- umg_edge(lhs, rhs, "dep", label = lab, fixed = fixed)
    } else if (op == "~") {
      edges[[k]] <- umg_edge(rhs, lhs, "dep", label = lab, fixed = fixed)
    } else if (op == "~~" && lhs != rhs) {
      edges[[k]] <- umg_edge(lhs, rhs, "cov", label = lab, fixed = fixed)
    } else {
      k <- k - 1L  # diagonal variance: annotation, not an edge
      nd <- nodes[[lhs]]
      nd$dist <- paste0("var = ", if (!is.null(fixed)) fixed
                        else if (pt$free[r] == 0L) "fixed" else "free")
      nodes[[lhs]] <- nd
    }
  }

  if (bayesian)
    for (v in names(nodes))
      nodes[[v]]$annot <- .umg_annot_add(nodes[[v]]$annot, "prior")

  plates <- list(umg_plate("person", names(nodes), plate_index))
  umg_model(nodes, edges, plates,
            badge = "statistical")
}

#' Build a UMG from a blavaan model
#'
#' Translates a fitted Bayesian structural equation model from the
#' \pkg{blavaan} package into a UMG. The graph topology is identical to
#' that of the frequentist [umg_from_lavaan()] translation; what
#' differs is the interpretive reading, since every free parameter
#' carries a prior. The construction makes literal the article's claim
#' that the Bayesian and frequentist forms of a model are the same
#' diagram differing only in which vertices have been prior-closed.
#'
#' @param object A fitted blavaan object.
#' @param plate_index Index label for the person plate.
#' @return An object of class `umg`.
#' @export
umg_from_blavaan <- function(object, plate_index = "i = 1, ..., N") {
  .umg_require("blavaan", "umg_from_blavaan")
  .umg_require("lavaan", "umg_from_blavaan")
  pt <- lavaan::parameterTable(object)
  .umg_build_partable(pt, plate_index = plate_index, bayesian = TRUE)
}

#' Build a UMG from an lme4 formula
#'
#' Parses an lme4-style mixed-model formula and constructs the
#' nested-plate UMG: the outcome and within-cluster covariates sit in
#' the inner (occasion) plate, random coefficients are latent
#' continuous vertices in the cluster plate, their population means
#' are parameter vertices outside all plates (the
#' parameter-promotion rendering of fixed vs. random effects), and
#' random-effect covariances appear as `cov` edges.
#'
#' @param formula An lme4 model formula, e.g.
#'   `Reaction ~ Days + (Days | Subject)`.
#' @param data Optional data frame; only used to label index sizes.
#' @return An object of class `umg`.
#' @export
umg_from_lmer <- function(formula, data = NULL) {
  .umg_require("lme4", "umg_from_lmer")
  .umg_from_mixed(formula, data = data, bayesian = FALSE)
}

# Internal: parse an lme4-style mixed-model formula into a nested-plate
# UMG. Shared by umg_from_lmer() and umg_from_brms(). Assumes lme4 is
# available (checked by the callers).
.umg_from_mixed <- function(formula, data = NULL, bayesian = FALSE) {
  bars <- lme4::findbars(formula)
  if (!length(bars))
    stop("Formula contains no random-effect terms.")
  if (length(bars) > 1L)
    warning("Only the first random-effect term is rendered; ",
            "extend by hand for crossed or multiple terms.")
  bar <- bars[[1L]]
  group <- deparse(bar[[3L]])
  reterms <- attr(stats::terms(
    stats::reformulate(deparse(bar[[2L]]))), "term.labels")
  has_rint <- !identical(attr(stats::terms(
    stats::reformulate(deparse(bar[[2L]]))), "intercept"), 0L)

  outcome <- deparse(formula[[2L]])
  fixed_form <- lme4::nobars(formula)
  fixed_terms <- attr(stats::terms(fixed_form), "term.labels")

  N <- if (!is.null(data) && group %in% names(data)) {
    length(unique(data[[group]]))
  } else {
    if (!is.null(data) && !group %in% names(data))
      warning("Grouping variable '", group,
              "' not found in 'data'; using symbolic index size.",
              call. = FALSE)
    "N"
  }
  Ti <- "T_i"

  nodes <- list()
  edges <- list()
  inner <- character(0)

  nodes[[outcome]] <- umg_node(outcome, paste0("$", outcome, "_{ti}$"),
                               observed = TRUE,
                               dist = "N(mu_ti, sigma^2)")
  inner <- c(inner, outcome)

  cluster_members <- character(0)
  k <- 0L

  # random intercept
  if (has_rint) {
    nodes[["b0"]] <- umg_node("b0", "$\\beta_{0i}$", observed = FALSE)
    nodes[["g0"]] <- umg_node("g0", "$\\gamma_{0}$", role = "par")
    k <- k + 1L; edges[[k]] <- umg_edge("g0", "b0", "dep")
    k <- k + 1L; edges[[k]] <- umg_edge("b0", outcome, "dep")
    cluster_members <- c(cluster_members, "b0")
  }

  # random slopes and their covariates
  for (j in seq_along(reterms)) {
    v <- reterms[j]
    bj <- paste0("b", j); gj <- paste0("g", j)
    if (!v %in% names(nodes)) {
      nodes[[v]] <- umg_node(v, paste0("$", v, "_{ti}$"),
                             observed = TRUE, dist = "free")
      inner <- c(inner, v)
    }
    nodes[[bj]] <- umg_node(bj, paste0("$\\beta_{", j, "i}$"),
                            observed = FALSE)
    nodes[[gj]] <- umg_node(gj, paste0("$\\gamma_{", j, "}$"),
                            role = "par")
    k <- k + 1L; edges[[k]] <- umg_edge(gj, bj, "dep")
    k <- k + 1L; edges[[k]] <- umg_edge(bj, outcome, "dep")
    k <- k + 1L; edges[[k]] <- umg_edge(v, outcome, "dep")
    cluster_members <- c(cluster_members, bj)
  }

  # purely fixed (non-random) covariate effects
  for (v in setdiff(fixed_terms, reterms)) {
    if (!v %in% names(nodes)) {
      nodes[[v]] <- umg_node(v, paste0("$", v, "_{ti}$"),
                             observed = TRUE, dist = "free")
      inner <- c(inner, v)
      k <- k + 1L; edges[[k]] <- umg_edge(v, outcome, "dep")
    }
  }

  # random-effect covariances
  if (length(cluster_members) > 1L) {
    cm <- cluster_members
    for (a in seq_along(cm)) {
      for (b in seq_along(cm)) {
        if (a < b) {
          k <- k + 1L
          edges[[k]] <- umg_edge(cm[a], cm[b], "cov",
                                 label = paste0("$\\tau_{", a - 1,
                                                b - 1, "}$"))
        }
      }
    }
  }

  if (bayesian)
    for (v in names(nodes))
      if (nodes[[v]]$role == "par") {
        nodes[[v]] <- umg_node(v, nodes[[v]]$label, observed = FALSE,
                               dist = "prior")
      }

  plates <- list(
    umg_plate("occasion", inner,
              paste0("t = 1, ..., ", Ti), parent = "cluster"),
    umg_plate("cluster", c(inner, cluster_members),
              paste0("i = 1, ..., ", N))
  )
  umg_model(nodes, edges, plates)
}

#' Build a UMG from a fitted mirt model
#'
#' Translates a fitted item response model from the mirt package into a
#' crossed-plate UMG: latent ability dimensions become latent
#' continuous vertices in the person plate, the observed responses
#' become an observed categorical vertex at the crossing of the person
#' and item plates, and the item parameters become fixed-unknown
#' diamonds in the item plate. The number of ability dimensions is read
#' from the fitted object; the item-parameter glyphs are generic
#' (discrimination and location), since the diagram represents the
#' structure rather than per-item estimates.
#'
#' @param object A fitted `SingleGroupClass`/`mirt` object, or an
#'   integer giving the number of latent dimensions (for a quick
#'   structural sketch without a fit).
#' @param model Item-model label deciding which item-parameter
#'   vertices to draw: one of `"2PL"`, `"1PL"`, `"3PL"`, `"graded"`.
#'   When `object` is a fitted mirt model and `model` is not supplied,
#'   the item type is read from the fitted object (`Rasch` maps to
#'   `"1PL"`; `graded`, `grsm`, `gpcm`, and `gpcmIRT` map to
#'   `"graded"`); an explicit `model` argument overrides the fit.
#' @return An object of class `umg`.
#' @export
umg_from_mirt <- function(object, model = c("2PL", "1PL", "3PL",
                                            "graded")) {
  model_missing <- missing(model)
  model <- match.arg(model)
  nfact <- 1L
  if (!is.numeric(object)) {
    if (!requireNamespace("mirt", quietly = TRUE))
      stop("Package 'mirt' is required for fitted-object input.")
    nfact <- tryCatch(mirt::extract.mirt(object, "nfact"),
                      error = function(e) 1L)
    if (model_missing) {
      it <- tryCatch(unique(mirt::extract.mirt(object, "itemtype")),
                     error = function(e) character(0))
      map <- c(Rasch = "1PL", `1PL` = "1PL", `2PL` = "2PL",
               `3PL` = "3PL", graded = "graded", grsm = "graded",
               gpcm = "graded", gpcmIRT = "graded")
      known <- map[intersect(it, names(map))]
      if (length(unique(known)) == 1L && length(known) == length(it)) {
        model <- unique(known)
      } else if (length(it)) {
        warning("umg_from_mirt(): item type(s) ",
                paste(it, collapse = ", "),
                " not uniquely mapped; drawing the '", model,
                "' structure. Pass 'model' explicitly to override.",
                call. = FALSE)
      }
    }
  } else {
    nfact <- as.integer(object)
  }

  nodes <- list()
  ability <- character(0)
  for (f in seq_len(nfact)) {
    nm <- paste0("theta", f)
    lab <- if (nfact == 1L) "$\\theta_i$" else paste0("$\\theta_{", f, "i}$")
    nodes[[nm]] <- umg_node(nm, lab, observed = FALSE, dist = "N(0, 1)")
    ability <- c(ability, nm)
  }
  nodes[["u"]] <- umg_node("u", "$u_{ij}$", observed = TRUE,
                           support = "categorical",
                           dist = if (model == "graded")
                             "Ordered(p_ij)" else "Bernoulli(p_ij)")
  nodes[["b"]] <- umg_node("b", "$b_j$", role = "par")

  edges <- c(lapply(ability, function(a) umg_edge(a, "u", "dep")),
             list(umg_edge("b", "u", "dep")))
  item_members <- c("u", "b")
  if (model %in% c("2PL", "3PL", "graded")) {
    nodes[["a"]] <- umg_node("a", "$a_j$", role = "par")
    edges <- c(edges, list(umg_edge("a", "u", "dep")))
    item_members <- c(item_members, "a")
  }
  if (model == "3PL") {
    nodes[["g"]] <- umg_node("g", "$g_j$", role = "par")
    edges <- c(edges, list(umg_edge("g", "u", "dep")))
    item_members <- c(item_members, "g")
  }

  plates <- list(
    umg_plate("person", c(ability, "u"), "i = 1, ..., N"),
    umg_plate("item", item_members, "j = 1, ..., J")
  )
  umg_model(unname(nodes), edges, plates)
}
