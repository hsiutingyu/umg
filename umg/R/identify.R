# ============================================================
# Title:  Identification and conditional-independence tooling
# File:   identify.R (package umg)
# Author: H.-T. Yu
# Date:   2026-06-19
# ============================================================
# Functions that read identification-relevant information off a UMG,
# operationalising the article's claim that necessary conditions for
# identification are visible on the page: scaling-mark checks for
# latent continuous vertices, a graphical counting (t-)rule, the
# label-switching symmetry of mixtures, and a d-separation reader for
# the conditional independencies the model implies. None of these
# replaces a formal identification analysis; each catches a routine
# error at the drawing board.

#' Check latent-variable scaling marks
#'
#' Every latent continuous random vertex must have its scale fixed,
#' either by a unit-valued outgoing loading (marker method), by a
#' fixed variance (variance-standardisation method), or, for a
#' formative composite, by a unit-valued incoming weight from an
#' observed cause (the marker convention for composites). This function
#' inspects each such vertex and reports whether a scaling mark is
#' present, exposing the single most common specification error in
#' latent variable modelling as a missing mark rather than a
#' nonconvergence.
#'
#' A constant parent (a `const` vertex with an edge into the latent
#' vertex) fixes the *location* of the latent variable, not its scale:
#' it pins the mean, and a variance can still be traded against the
#' loadings. It is therefore reported separately in `location_fixed`
#' and does not count as a scaling mark.
#'
#' @param model An object of class `umg`.
#' @return A data frame with one row per latent continuous random
#'   vertex and columns `vertex`, `scaled` (logical), `via` (the
#'   scaling mechanism detected: `"marker loading"`, `"fixed
#'   variance"`, `"marker weight"`, or `"none"`), and
#'   `location_fixed` (logical; informational, `TRUE` when a constant
#'   parent fixes the location).
#' @examples
#' umg_check_scaling(umg_factor("F", paste0("y", 1:3)))
#' umg_check_scaling(umg_formative(paste0("x", 1:3), outcomes = c("y1", "y2")))
#' @export
umg_check_scaling <- function(model) {
  stopifnot(inherits(model, "umg"))
  nodes <- model$nodes
  latent_cont <- names(Filter(function(v)
    !v$observed && v$role == "rv" && v$support == "continuous", nodes))

  out <- lapply(latent_cont, function(v) {
    out_edges <- Filter(function(e)
      e$kind == "dep" && e$from == v, model$edges)
    unit_loading <- any(vapply(out_edges, function(e)
      !is.null(e$fixed) && isTRUE(e$fixed == 1), logical(1)))
    fixed_var <- .umg_fixed_var_dist(nodes[[v]]$dist)
    # formative composite: a unit weight from an observed cause fixes
    # the composite's scale to that cause's scale
    in_edges <- Filter(function(e)
      e$kind == "dep" && e$to == v && nodes[[e$from]]$observed &&
        nodes[[e$from]]$role == "rv", model$edges)
    unit_weight <- any(vapply(in_edges, function(e)
      !is.null(e$fixed) && isTRUE(e$fixed == 1), logical(1)))
    # a constant parent fixes the location (mean), not the scale
    const_parent <- any(vapply(model$edges, function(e)
      e$to == v && nodes[[e$from]]$role == "const", logical(1)))
    via <- if (unit_loading) "marker loading"
           else if (fixed_var) "fixed variance"
           else if (unit_weight) "marker weight"
           else "none"
    data.frame(vertex = v, scaled = via != "none", via = via,
               location_fixed = const_parent,
               stringsAsFactors = FALSE)
  })
  if (!length(out))
    return(data.frame(vertex = character(0), scaled = logical(0),
                      via = character(0), location_fixed = logical(0),
                      stringsAsFactors = FALSE))
  do.call(rbind, out)
}

#' Graphical parameter count (t-rule)
#'
#' Applies the classical counting rule for covariance-structure models:
#' a model can be identified only if the number of free parameters does
#' not exceed the number of distinct pieces of information the observed
#' variables supply. The count is read from the diagram by tallying
#' free `dep` edges, free `cov` edges, and vertex variances against the
#' number of non-redundant observed (co)variances. The rule supplies a
#' necessary, not sufficient, condition; a non-negative degrees of
#' freedom does not guarantee identification.
#'
#' @param model An object of class `umg`.
#' @param meanstructure Logical; include the observed means in the
#'   information count (`p` additional moments) and the free
#'   intercepts/means in the parameter count (default `FALSE`). See
#'   Details for how the free means are counted.
#' @param n_means Optional integer overriding the automatic count of
#'   free mean-structure parameters when `meanstructure = TRUE`;
#'   ignored otherwise.
#' @details With `meanstructure = TRUE`, the free mean-structure
#'   parameters are counted as follows. If every random vertex carries
#'   a mean annotation of the form `mean = free`, `mean = 0`, or
#'   `mean = <value>` in its `annot` field (as written by
#'   [umg_from_lavaan()] from a fit with a mean structure), the count is
#'   the number of vertices annotated `mean = free`. Otherwise the
#'   diagram does not carry intercept fixing, and the rule assumes the
#'   growth-model convention: the indicators of latent factors have
#'   intercepts fixed at zero, so the free means are the means of the
#'   latent source vertices (latent random vertices without an incoming
#'   directed edge) plus the intercepts of the observed vertices that
#'   are not regressed on a latent vertex. This reproduces lavaan's
#'   `growth()` count (for a linear growth model over four occasions,
#'   14 moments, 9 free parameters, 5 degrees of freedom). For other
#'   conventions supply `n_means`: for a CFA fitted with free observed
#'   intercepts and zero latent means, `n_means = p` (the number of
#'   observed vertices), in which case the mean structure is saturated
#'   and the degrees of freedom are unchanged.
#' @return A list with the data information count, the free-parameter
#'   breakdown, the total, the implied degrees of freedom, and a
#'   logical element `applicable`. The rule counts second-order
#'   moments and therefore applies only to models whose random
#'   vertices are all continuous; when the model contains a
#'   categorical random vertex (mixtures, latent classes, IRT, DCM),
#'   `applicable` is `FALSE`, the counts are returned as read but the
#'   degrees of freedom are set to `NA`, and a warning is issued.
#' @examples
#' umg_count_parameters(umg_factor("F", paste0("y", 1:6)))
#' umg_count_parameters(umg_growth(4), meanstructure = TRUE)  # df = 5
#' @export
umg_count_parameters <- function(model, meanstructure = FALSE,
                                 n_means = NULL) {
  stopifnot(inherits(model, "umg"))
  nodes <- model$nodes
  obs <- names(Filter(function(v) v$observed && v$role == "rv", nodes))
  p <- length(obs)
  info <- p * (p + 1) / 2 + if (meanstructure) p else 0

  free_dep <- sum(vapply(model$edges, function(e)
    e$kind == "dep" && is.null(e$fixed) &&
      nodes[[e$from]]$role != "par" && nodes[[e$from]]$role != "const",
    logical(1)))
  free_cov <- sum(vapply(model$edges, function(e)
    e$kind == "cov" && is.null(e$fixed), logical(1)))
  # one variance per random vertex, minus any variance fixed to a
  # numeric value by its distribution annotation (whether or not the
  # vertex is also scaled by a marker loading, and whether it is
  # latent or observed)
  rv <- names(Filter(function(v) v$role == "rv", nodes))
  fixed_var <- names(Filter(function(v)
    v$role == "rv" && .umg_fixed_var_dist(v$dist), nodes))
  n_var <- length(rv) - length(fixed_var)
  free_mean <- if (!meanstructure) 0 else if (!is.null(n_means)) {
    stopifnot(is.numeric(n_means), length(n_means) == 1L, !is.na(n_means))
    as.numeric(n_means)
  } else .umg_free_means(model)

  applicable <- !any(vapply(nodes, function(v)
    v$role == "rv" && v$support == "categorical", logical(1)))
  if (!applicable)
    warning("umg_count_parameters(): the covariance counting rule ",
            "assumes continuous random vertices; the model contains ",
            "categorical random vertices, so the count is not a valid ",
            "identification check.", call. = FALSE)

  total <- free_dep + free_cov + n_var + free_mean
  list(
    data_information = info,
    free = list(loadings_regressions = free_dep, covariances = free_cov,
                variances = n_var, means = free_mean),
    free_total = total,
    df = if (applicable) info - total else NA_real_,
    applicable = applicable
  )
}

#' Flag label-switching symmetry in mixtures
#'
#' Mixture and latent class models are identified only up to a
#' permutation of the latent classes, the label-switching
#' indeterminacy. This function reports the latent categorical random
#' vertices whose value permutation leaves the diagram invariant,
#' making the indeterminacy a visible property of the specification.
#'
#' @param model An object of class `umg`.
#' @return A character vector of latent categorical random vertex
#'   names (empty if the model has no mixture component).
#' @examples
#' umg_labelswitching(umg_mixture(umg_growth(4), c("I", "S")))
#' @export
umg_labelswitching <- function(model) {
  stopifnot(inherits(model, "umg"))
  names(Filter(function(v)
    !v$observed && v$role == "rv" && v$support == "categorical",
    model$nodes))
}

# Internal: augment a model's directed subgraph with a latent common
# cause for every covariance edge, returning a list of directed edges
# (from, to) over an extended node set. This projects the acyclic
# directed mixed graph onto a DAG for d-separation reasoning.
.umg_augment_dag <- function(model) {
  vars <- names(model$nodes)
  edges <- lapply(.umg_directed(model), function(e) c(e$from, e$to))
  k <- 0L
  latents <- character(0)
  for (e in .umg_cov(model)) {
    k <- k + 1L
    L <- paste0("_L", k)
    latents <- c(latents, L)
    edges <- c(edges, list(c(L, e$from)), list(c(L, e$to)))
  }
  list(vars = c(vars, latents), edges = edges, latents = latents)
}

# Internal: parents / children / descendants on an augmented DAG.
.umg_dag_parents <- function(dag, v)
  vapply(Filter(function(e) e[2] == v, dag$edges), `[`, character(1), 1)
.umg_dag_children <- function(dag, v)
  vapply(Filter(function(e) e[1] == v, dag$edges), `[`, character(1), 2)
.umg_dag_descendants <- function(dag, v) {
  seen <- character(0); stack <- v
  while (length(stack)) {
    cur <- stack[1]; stack <- stack[-1]
    ch <- .umg_dag_children(dag, cur)
    new <- setdiff(ch, seen)
    seen <- c(seen, new); stack <- c(stack, new)
  }
  seen
}

# Internal: ancestors of a vertex set (including the set itself) on an
# augmented DAG.
.umg_dag_ancestors <- function(dag, vs) {
  seen <- vs; stack <- vs
  while (length(stack)) {
    cur <- stack[1]; stack <- stack[-1]
    new <- setdiff(.umg_dag_parents(dag, cur), seen)
    seen <- c(seen, new); stack <- c(stack, new)
  }
  unique(seen)
}

# Internal: d-separation by the moralized ancestral graph criterion
# (Lauritzen, Dawid, Larsen, & Leimer, 1990): x and y are d-separated
# by z in a DAG iff z separates x and y in the moral graph of the
# ancestral subgraph induced by {x, y} on z. This runs in time linear
# in the size of the graph, unlike path enumeration, and is therefore
# exact on dense graphs as well.
.umg_dsep_moral <- function(dag, x, y, z) {
  anc <- .umg_dag_ancestors(dag, unique(c(x, y, z)))
  nbr <- stats::setNames(rep(list(character(0)), length(anc)), anc)
  add <- function(a, b) {
    nbr[[a]] <<- c(nbr[[a]], b)
    nbr[[b]] <<- c(nbr[[b]], a)
  }
  for (e in dag$edges)
    if (e[1] %in% anc && e[2] %in% anc) add(e[1], e[2])
  for (v in anc) {
    pa <- intersect(.umg_dag_parents(dag, v), anc)
    if (length(pa) > 1L)
      for (a in seq_along(pa))
        for (b in seq_along(pa))
          if (a < b) add(pa[a], pa[b])
  }
  # breadth-first search from x avoiding z; connected iff y is reached
  seen <- c(x, z); queue <- x
  while (length(queue)) {
    cur <- queue[1]; queue <- queue[-1]
    for (w in unique(nbr[[cur]])) {
      if (w == y) return(FALSE)
      if (!(w %in% seen)) {
        seen <- c(seen, w); queue <- c(queue, w)
      }
    }
  }
  TRUE
}

#' Test d-separation in a UMG
#'
#' Reads a conditional-independence claim off the diagram by the
#' d-separation criterion. Covariance edges are treated as latent
#' common causes (the projection of an acyclic directed mixed graph
#' onto a DAG), so that an unanalysed association behaves as a fork.
#' The test generalises the vanishing-tetrad reasoning of the
#' factor-analytic tradition and supplies the model's testable
#' implications.
#'
#' @param model An object of class `umg`.
#' @param x,y Vertex names whose separation is queried.
#' @param given Character vector of conditioning vertices (default
#'   none); may not contain `x` or `y`.
#' @return `TRUE` if `x` and `y` are d-separated given `given`,
#'   `FALSE` otherwise.
#' @details The test is carried out by the moralized ancestral graph
#'   criterion (Lauritzen, Dawid, Larsen, & Leimer, 1990), which is
#'   exact and runs in time linear in the size of the graph, so dense
#'   diagrams (for example, saturated network models) are handled
#'   without approximation.
#' @examples
#' m <- umg_mediation(direct = FALSE)
#' umg_dsep(m, "X", "Y")             # FALSE: connected through M
#' umg_dsep(m, "X", "Y", given = "M")  # TRUE: blocked by M
#' @export
umg_dsep <- function(model, x, y, given = character(0)) {
  stopifnot(inherits(model, "umg"))
  if (!all(c(x, y, given) %in% names(model$nodes)))
    stop("All vertices must be declared in the model.", call. = FALSE)
  if (x == y || x %in% given || y %in% given)
    stop("'x' and 'y' must be distinct and not part of 'given'.",
         call. = FALSE)
  dag <- .umg_augment_dag(model)
  .umg_dsep_moral(dag, x, y, given)
}

#' Enumerate basis-set implied conditional independencies
#'
#' Returns the set of conditional independencies that the model implies
#' under the local Markov property: each vertex is independent of its
#' non-descendants given its parents in the directed subgraph. These
#' are the testable implications a researcher can check against the
#' data before trusting the specification.
#'
#' @param model An object of class `umg`.
#' @param observed_only Logical; restrict the statements to those that
#'   are directly testable (default `TRUE`), meaning that both
#'   vertices *and every vertex in the conditioning set* are observed.
#'   Statements conditioned on latent vertices are implications of the
#'   model but cannot be checked against data directly; set
#'   `observed_only = FALSE` to list them as well.
#' @return A data frame with columns `x`, `y`, and `given` (a
#'   comma-separated conditioning set), one row per implied
#'   independence. Independence is symmetric, so each statement is
#'   listed once, in canonical form: `x` precedes `y` in the model's
#'   vertex order, and the conditioning set is listed in vertex order.
#' @examples
#' umg_implied_ci(umg_mediation(direct = FALSE))
#' @export
umg_implied_ci <- function(model, observed_only = TRUE) {
  stopifnot(inherits(model, "umg"))
  dag <- .umg_augment_dag(model)
  vars <- names(model$nodes)   # original vertices only
  parents <- .umg_parents(model)
  canon <- function(vs) vars[sort(match(vs, vars))]

  rows <- list()
  for (v in vars) {
    pa <- parents[[v]]
    desc <- .umg_dag_descendants(dag, v)
    nondesc <- setdiff(vars, c(v, desc, pa))
    for (w in nondesc) {
      if (umg_dsep(model, v, w, given = pa)) {
        if (observed_only &&
            !(model$nodes[[v]]$observed && model$nodes[[w]]$observed &&
              all(vapply(pa, function(pp) model$nodes[[pp]]$observed,
                         logical(1)))))
          next
        # canonical form, so that (v, w | Z) and (w, v | Z), which are
        # the same statement, collapse to one row below
        xy <- canon(c(v, w))
        rows[[length(rows) + 1L]] <- data.frame(
          x = xy[1L], y = xy[2L],
          given = paste(canon(pa), collapse = ", "),
          stringsAsFactors = FALSE)
      }
    }
  }
  if (!length(rows))
    return(data.frame(x = character(0), y = character(0),
                      given = character(0), stringsAsFactors = FALSE))
  out <- unique(do.call(rbind, rows))
  rownames(out) <- NULL
  out
}

# Internal: number of distinct conditional-independence statements in
# an implied-CI data frame, counting (x, y | Z) and (y, x | Z) once.
.umg_n_ci <- function(ci) {
  if (is.null(ci) || !nrow(ci)) return(0L)
  length(unique(paste(pmin(ci$x, ci$y), pmax(ci$x, ci$y), ci$given,
                      sep = "\r")))
}

#' Identification summary for a UMG
#'
#' Collects the identification-relevant readings of a diagram into a
#' single object: scaling-mark checks, the graphical parameter count,
#' the label-switching flag, and the number of implied conditional
#' independencies. Printing the object gives a compact report.
#'
#' @param model An object of class `umg`.
#' @param meanstructure,n_means Passed to [umg_count_parameters()].
#' @return An object of class `umg_identification`.
#' @examples
#' umg_identify(umg_factor("F", paste0("y", 1:6)))
#' @export
umg_identify <- function(model, meanstructure = FALSE, n_means = NULL) {
  stopifnot(inherits(model, "umg"))
  res <- list(
    scaling = umg_check_scaling(model),
    count = umg_count_parameters(model, meanstructure = meanstructure,
                                 n_means = n_means),
    label_switching = umg_labelswitching(model),
    implied_ci = umg_implied_ci(model)
  )
  class(res) <- "umg_identification"
  res
}

#' Print a UMG identification summary
#'
#' Formats the components collected by [umg_identify()] into a compact
#' report: latent scaling status, the counting-rule degrees of freedom,
#' any label-switching indeterminacy, and the number of implied
#' conditional independencies.
#'
#' @param x An object of class `umg_identification`.
#' @param ... Further arguments passed to or from other methods
#'   (currently unused).
#' @return The object `x`, invisibly.
#' @examples
#' print(umg_identify(umg_factor("F", paste0("y", 1:6))))
#' @export
print.umg_identification <- function(x, ...) {
  cat("UMG identification summary\n")
  cat("--------------------------\n")
  sc <- x$scaling
  if (nrow(sc)) {
    unscaled <- sc$vertex[!sc$scaled]
    cat("Latent scaling: ", nrow(sc), " latent continuous vertex(es); ",
        if (length(unscaled)) paste0("UNSCALED: ",
                                     paste(unscaled, collapse = ", "))
        else "all scaled", "\n", sep = "")
  } else {
    cat("Latent scaling: no latent continuous vertices.\n")
  }
  cnt <- x$count
  if (isFALSE(cnt$applicable)) {
    cat("Counting rule: not applicable (categorical random vertices;\n",
        "  the covariance counting rule assumes continuous support).\n",
        sep = "")
  } else {
    cat(sprintf(
      "Counting rule: %d data moments, %d free parameters, df = %d%s\n",
      cnt$data_information, cnt$free_total, cnt$df,
      if (cnt$df < 0) "  (under-identified by the t-rule)" else ""))
  }
  if (length(x$label_switching))
    cat("Label switching: identified up to permutation of {",
        paste(x$label_switching, collapse = ", "), "}\n", sep = "")
  cat(sprintf("Implied conditional independencies (observed): %d\n",
              .umg_n_ci(x$implied_ci)))
  cat("Note: necessary conditions only; not a formal identification proof.\n")
  invisible(x)
}
