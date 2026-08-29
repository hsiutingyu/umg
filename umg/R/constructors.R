# ============================================================
# Title:  UMG constructors: nodes, edges, plates, model
# File:   constructors.R (package umg)
# Author: H.-T. Yu
# Date:   2026-06-12
# ============================================================

#' Create a UMG vertex
#'
#' Vertices are typed on three orthogonal dimensions: observability
#' (observed vs. latent), support (continuous vs. categorical), and
#' inferential role (random variable, fixed unknown parameter,
#' deterministic node, or known constant).
#'
#' @param name Unique vertex identifier (character scalar).
#' @param label Display label; defaults to `name`. May contain TeX
#'   math (e.g., `"$\\eta_{1i}$"`) for TikZ export.
#' @param observed Logical; `TRUE` for observed vertices. Ignored for
#'   roles `"par"` and `"const"`, which are never observed data.
#' @param support `"continuous"` or `"categorical"`.
#' @param role `"rv"` (random variable), `"par"` (fixed unknown
#'   parameter), `"det"` (deterministic), or `"const"` (known constant).
#' @param dist Optional distribution annotation (character), e.g.
#'   `"N(0, 1)"`. Required for source random vertices (rule W2).
#' @param fill Optional fill colour overriding the theme default for
#'   this vertex (any R colour specification). Useful for highlighting
#'   a subset of vertices without editing the theme.
#' @param annot Optional free-form annotation string carried with the
#'   vertex (e.g., a convergence diagnostic such as `"Rhat = 1.00"`).
#'   Annotations are available to renderers and exporters.
#' @return An object of class `umg_node`.
#' @examples
#' umg_node("eta1", "$\\eta_{1i}$", observed = FALSE)
#' umg_node("c", "$c_i$", observed = FALSE, support = "categorical",
#'          dist = "Categorical(pi)")
#' umg_node("y1", "$y_{1i}$", observed = TRUE, fill = "grey60",
#'          annot = "reverse-scored")
#' @export
umg_node <- function(name,
                     label = name,
                     observed = FALSE,
                     support = c("continuous", "categorical"),
                     role = c("rv", "par", "det", "const"),
                     dist = NULL,
                     fill = NULL,
                     annot = NULL) {
  support <- match.arg(support)
  role <- match.arg(role)
  stopifnot(is.character(name), length(name) == 1L, nzchar(name))
  if (!is.null(fill))
    stopifnot(is.character(fill), length(fill) == 1L)
  if (!is.null(annot))
    stopifnot(is.character(annot), length(annot) == 1L)
  node <- list(name = name, label = label, observed = isTRUE(observed),
               support = support, role = role, dist = dist,
               fill = fill, annot = annot)
  class(node) <- "umg_node"
  node
}

#' Create a UMG edge
#'
#' @param from,to Vertex names (character scalars).
#' @param kind Edge kind: `"dep"` (stochastic dependence), `"cov"`
#'   (symmetric covariance), `"det"` (deterministic assignment), or
#'   `"mix"` (mixture selection from a categorical vertex).
#' @param label Optional parameter label (e.g., `"$\\lambda_2$"`); an
#'   edge label is shorthand for a parameter vertex (parameter
#'   promotion; see the accompanying article, Section 4.5).
#' @param fixed Optional fixed value (e.g., `1` for a scaling loading).
#' @param aggregate Logical; `TRUE` marks a deterministic (`det`) edge
#'   as an aggregation over a replicated index, for example a cluster
#'   mean computed from occasion-level observations. Such an edge runs
#'   from a vertex inside a plate to a vertex outside it, which the
#'   index-licensing rule W5 would otherwise refuse (see
#'   [umg_validate()]); marking it `aggregate = TRUE` exempts it from
#'   that rule. Only meaningful for `det` edges; default `FALSE`.
#' @return An object of class `umg_edge`.
#' @examples
#' umg_edge("eta1", "y1", kind = "dep", fixed = 1)
#' umg_edge("eta1", "eta2", kind = "cov", label = "$\\psi_{21}$")
#' umg_edge("y", "ybar", kind = "det", aggregate = TRUE)
#' @export
umg_edge <- function(from, to,
                     kind = c("dep", "cov", "det", "mix"),
                     label = "", fixed = NULL, aggregate = FALSE) {
  kind <- match.arg(kind)
  stopifnot(is.character(from), length(from) == 1L,
            is.character(to), length(to) == 1L)
  if (is.null(label)) label <- ""
  if (!is.character(label) || length(label) != 1L || is.na(label))
    stop("'label' must be a character scalar (use \"\" for no label).",
         call. = FALSE)
  if (!is.null(fixed) &&
      (length(fixed) != 1L || is.na(fixed) ||
       !(is.numeric(fixed) || is.character(fixed))))
    stop("'fixed' must be NULL or a non-missing numeric or character ",
         "scalar.", call. = FALSE)
  if (!is.logical(aggregate) || length(aggregate) != 1L || is.na(aggregate))
    stop("'aggregate' must be TRUE or FALSE.", call. = FALSE)
  if (aggregate && kind != "det")
    stop("'aggregate = TRUE' is only meaningful for deterministic ",
         "('det') edges.", call. = FALSE)
  edge <- list(from = from, to = to, kind = kind,
               label = label, fixed = fixed, aggregate = aggregate)
  class(edge) <- "umg_edge"
  edge
}

#' Create a UMG plate
#'
#' Plates encode exchangeable replication; nested plates encode
#' hierarchy and overlapping plates encode crossing.
#'
#' @param name Plate identifier.
#' @param members Character vector of vertex names in the plate scope.
#' @param index Index label, e.g. `"i = 1, ..., N"`.
#' @param parent Optional name of the enclosing plate (nesting).
#' @return An object of class `umg_plate`.
#' @examples
#' umg_plate("person", c("eta1", "y1"), index = "i = 1, ..., N")
#' @export
umg_plate <- function(name, members, index, parent = NULL) {
  stopifnot(is.character(name), length(name) == 1L,
            is.character(members), length(members) >= 1L,
            is.character(index), length(index) == 1L)
  plate <- list(name = name, members = members, index = index,
                parent = parent)
  class(plate) <- "umg_plate"
  plate
}

#' Assemble and validate a Unified Model Graph
#'
#' @param nodes List of `umg_node` objects.
#' @param edges List of `umg_edge` objects.
#' @param plates List of `umg_plate` objects (may be empty).
#' @param badge Interpretive mode: `"statistical"` (default) or
#'   `"structural"`. Structural diagrams license causal (do-calculus)
#'   reading; statistical diagrams do not.
#' @param validate Logical; run well-formedness checks W1-W6 (default
#'   `TRUE`).
#' @return An object of class `umg`.
#' @seealso [umg_validate()], [plot.umg()], [umg_to_tikz()]
#' @examples
#' m <- umg_model(
#'   nodes = list(
#'     umg_node("eta", "$\\eta_i$", observed = FALSE, dist = "N(0, psi)"),
#'     umg_node("y1", "$y_{1i}$", observed = TRUE),
#'     umg_node("y2", "$y_{2i}$", observed = TRUE)
#'   ),
#'   edges = list(
#'     umg_edge("eta", "y1", "dep", fixed = 1),
#'     umg_edge("eta", "y2", "dep", label = "$\\lambda_2$")
#'   ),
#'   plates = list(umg_plate("person", c("eta", "y1", "y2"),
#'                           "i = 1, ..., N"))
#' )
#' @export
umg_model <- function(nodes, edges, plates = list(),
                      badge = c("statistical", "structural"),
                      validate = TRUE) {
  badge <- match.arg(badge)
  stopifnot(all(vapply(nodes, inherits, logical(1), "umg_node")),
            all(vapply(edges, inherits, logical(1), "umg_edge")),
            all(vapply(plates, inherits, logical(1), "umg_plate")))
  names(nodes) <- vapply(nodes, `[[`, character(1), "name")
  if (anyDuplicated(names(nodes)))
    stop("Duplicate vertex names: ",
         paste(unique(names(nodes)[duplicated(names(nodes))]),
               collapse = ", "))
  model <- list(nodes = nodes, edges = edges, plates = plates,
                badge = badge)
  class(model) <- "umg"
  if (validate) umg_validate(model)
  model
}

#' Print a Unified Model Graph
#'
#' Compact console summary of a `umg` object: the interpretive badge,
#' the vertex/edge/plate counts, and a tally of edge kinds.
#'
#' @param x An object of class `umg`.
#' @param ... Further arguments passed to or from other methods
#'   (currently unused).
#' @return The model `x`, invisibly.
#' @examples
#' print(umg_factor("F", paste0("y", 1:3)))
#' @export
print.umg <- function(x, ...) {
  cat("Unified Model Graph (", x$badge, " badge)\n", sep = "")
  cat("  vertices:", length(x$nodes),
      "| edges:", length(x$edges),
      "| plates:", length(x$plates), "\n")
  kinds <- table(vapply(x$edges, `[[`, character(1), "kind"))
  if (length(kinds))
    cat("  edge kinds:",
        paste(names(kinds), kinds, sep = "=", collapse = ", "), "\n")
  invisible(x)
}
