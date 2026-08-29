# ============================================================
# Title:  UMG well-formedness validation (rules W1-W6)
# File:   validate.R (package umg)
# Author: H.-T. Yu
# Date:   2026-06-12
# ============================================================

#' Validate well-formedness of a UMG
#'
#' Checks the well-formedness rules of the UMG grammar:
#' W1 acyclicity of the directed (dep/det/mix) subgraph;
#' W2 every source vertex is a parameter, a constant, or carries an
#' unconditional distribution annotation;
#' W3 covariance edges join random vertices only;
#' W4 mixing edges originate from latent categorical random vertices
#' and never target observed vertices;
#' W5 plates are coherent with the index structure (see Details);
#' W6 edge endpoints refer to declared vertices.
#' Rules are checked in linear time; violations raise errors,
#' advisory conditions raise warnings.
#'
#' @details Rule W5 has four clauses. (a) Plate membership refers to
#'   declared vertices, parents are declared plates, and nesting is
#'   acyclic. (b) Nesting is consistent with membership: every vertex
#'   of a plate nested inside another plate also belongs to the parent
#'   plate. (c) Index licensing: for every `dep` and `det` edge
#'   u -> v, the plates of u are a subset of the plates of v, so that a
#'   quantity replicated over an index can only feed quantities that are
#'   replicated over that index too (an item parameter may feed a
#'   person-by-item response, but not a person-level ability). A `det`
#'   edge created with `aggregate = TRUE` (see [umg_edge()]) is exempt,
#'   because an aggregate such as a cluster mean legitimately collapses
#'   an index. A `cov` edge joins vertices with identical plate
#'   membership. (d) Mixing: a `mix` edge from a class vertex c selects
#'   a class-specific value of its target, so every random vertex whose
#'   density uses that value (every `dep`-child of the target) must be
#'   replicated over the plates of c. The target itself is exempt from
#'   clause (c): it denotes a K-vector from which one element is
#'   selected per copy of c, and typically sits outside the plates of c.
#'
#' @param model An object of class `umg`.
#' @return Invisibly `TRUE` if all checks pass.
#' @export
umg_validate <- function(model) {
  stopifnot(inherits(model, "umg"))
  nodes <- model$nodes
  edges <- model$edges
  node_names <- names(nodes)

  # ----- W6: endpoint declaration --------------------------------
  for (e in edges) {
    if (!e$from %in% node_names)
      stop("Edge references undeclared vertex: ", e$from)
    if (!e$to %in% node_names)
      stop("Edge references undeclared vertex: ", e$to)
  }

  # ----- W1: acyclicity of directed subgraph ---------------------
  directed <- Filter(function(e) e$kind %in% c("dep", "det", "mix"),
                     edges)
  adj <- lapply(stats::setNames(vector("list", length(node_names)),
                                node_names), function(x) character(0))
  indeg <- stats::setNames(integer(length(node_names)), node_names)
  for (e in directed) {
    adj[[e$from]] <- c(adj[[e$from]], e$to)
    indeg[e$to] <- indeg[e$to] + 1L
  }
  queue <- node_names[indeg == 0L]
  seen <- 0L
  while (length(queue)) {
    v <- queue[1L]; queue <- queue[-1L]; seen <- seen + 1L
    for (w in adj[[v]]) {
      indeg[w] <- indeg[w] - 1L
      if (indeg[w] == 0L) queue <- c(queue, w)
    }
  }
  if (seen < length(node_names))
    stop("W1 violated: directed subgraph (dep/det/mix) contains a cycle.")

  # ----- W2: sources annotated -----------------------------------
  has_in <- unique(vapply(directed, `[[`, character(1), "to"))
  for (v in nodes) {
    if (v$role == "rv" && !(v$name %in% has_in) && is.null(v$dist))
      warning("W2: source random vertex '", v$name,
              "' lacks a distribution annotation.")
  }

  # ----- W3: covariance locality ---------------------------------
  for (e in edges) {
    if (e$kind == "cov") {
      r1 <- nodes[[e$from]]$role; r2 <- nodes[[e$to]]$role
      if (r1 != "rv" || r2 != "rv")
        stop("W3 violated: cov edge ", e$from, " <-> ", e$to,
             " joins non-random vertices.")
    }
  }

  # ----- W4: mixing edges ----------------------------------------
  for (e in edges) {
    if (e$kind == "mix") {
      src <- nodes[[e$from]]; tgt <- nodes[[e$to]]
      if (!(src$role == "rv" && src$support == "categorical" &&
            !src$observed))
        stop("W4 violated: mix edge source '", e$from,
             "' is not a latent categorical random vertex.")
      if (tgt$role == "rv" && tgt$observed)
        stop("W4 violated: mix edge targets observed vertex '",
             e$to, "' directly.")
    }
  }

  # ----- W5: plate coherence -------------------------------------
  plate_names <- vapply(model$plates, `[[`, character(1), "name")
  for (p in model$plates) {
    missing_members <- setdiff(p$members, node_names)
    if (length(missing_members))
      stop("W5 violated: plate '", p$name,
           "' contains undeclared vertices: ",
           paste(missing_members, collapse = ", "))
    if (!is.null(p$parent) && !p$parent %in% plate_names)
      stop("W5 violated: plate '", p$name,
           "' declares unknown parent '", p$parent, "'.")
  }
  # nesting acyclicity (follow parent chain)
  for (p in model$plates) {
    chain <- character(0)
    cur <- p
    while (!is.null(cur$parent)) {
      if (cur$parent %in% chain)
        stop("W5 violated: cyclic plate nesting at '", cur$parent, "'.")
      chain <- c(chain, cur$name)
      cur <- model$plates[[match(cur$parent, plate_names)]]
    }
  }
  # (b) nesting is consistent with membership: a vertex of a nested
  # plate is also a member of the enclosing plate
  for (p in model$plates) {
    if (is.null(p$parent)) next
    parent <- model$plates[[match(p$parent, plate_names)]]
    outside <- setdiff(p$members, parent$members)
    if (length(outside))
      stop("W5 violated: vertex '", outside[1L], "' is in plate '",
           p$name, "' but not in its parent plate '", p$parent, "'.")
  }
  # (c) index licensing: a dep/det edge u -> v needs plates(u) within
  # plates(v); a cov edge needs equal membership. (d) a mix edge from c
  # needs every random vertex whose density uses the selected value
  # (the dep-children of the target) replicated over plates(c); the
  # target itself is exempt from (c).
  plates_of <- .umg_plates_of(model)
  for (e in edges) {
    pu <- plates_of[[e$from]]; pv <- plates_of[[e$to]]
    if (e$kind %in% c("dep", "det")) {
      if (e$kind == "det" && isTRUE(e$aggregate)) next
      if (!all(pu %in% pv))
        stop("W5 violated: edge ", e$from, " -> ", e$to,
             " is not licensed by the index structure (plates of '",
             e$from, "' are not contained in the plates of '", e$to,
             "').")
    } else if (e$kind == "cov") {
      if (!setequal(pu, pv))
        stop("W5 violated: cov edge ", e$from, " <-> ", e$to,
             " joins vertices with different plate membership.")
    } else if (e$kind == "mix") {
      users <- unique(vapply(Filter(function(d)
        d$kind == "dep" && d$from == e$to, edges),
        `[[`, character(1), "to"))
      for (w in users) {
        if (nodes[[w]]$role != "rv") next
        if (!all(pu %in% plates_of[[w]]))
          stop("W5 violated: mix edge from '", e$from,
               "' selects a parameter used by '", w,
               "', which is not replicated over the plates of '",
               e$from, "'.")
      }
    }
  }

  invisible(TRUE)
}
