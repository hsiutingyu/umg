# ============================================================
# Title:  Internal helpers shared across the umg package
# File:   utils.R (package umg)
# Author: H.-T. Yu
# Date:   2026-06-19
# ============================================================
# Non-exported utilities. Kept in one place so that the graph
# algorithms used by validation, layout, identification, and the
# d-separation reader do not drift apart.

# Null-coalescing operator (internal).
`%||%` <- function(a, b) if (is.null(a) || length(a) == 0L) b else a

# Require a suggested package or stop with an informative message.
.umg_require <- function(pkg, fun) {
  if (!requireNamespace(pkg, quietly = TRUE))
    stop("Package '", pkg, "' is required for ", fun,
         "(). Install it with install.packages(\"", pkg, "\").",
         call. = FALSE)
  invisible(TRUE)
}

# Directed edges of a model (dep/det/mix form the directed subgraph).
.umg_directed <- function(model) {
  Filter(function(e) e$kind %in% c("dep", "det", "mix"), model$edges)
}

# Covariance (symmetric) edges of a model.
.umg_cov <- function(model) {
  Filter(function(e) e$kind == "cov", model$edges)
}

# Adjacency list of the directed subgraph (from -> to).
.umg_adj <- function(model) {
  nn <- names(model$nodes)
  adj <- stats::setNames(rep(list(character(0)), length(nn)), nn)
  for (e in .umg_directed(model)) adj[[e$from]] <- c(adj[[e$from]], e$to)
  adj
}

# Parents of each vertex in the directed subgraph.
.umg_parents <- function(model) {
  nn <- names(model$nodes)
  par <- stats::setNames(rep(list(character(0)), length(nn)), nn)
  for (e in .umg_directed(model)) par[[e$to]] <- c(par[[e$to]], e$from)
  par
}

# Plate membership of each vertex: a named list mapping every vertex
# name to the character vector of plate names containing it (empty for
# a vertex outside all plates). Shared by the W5 index-licensing checks
# and the DOT exporter.
.umg_plates_of <- function(model) {
  nn <- names(model$nodes)
  pn <- vapply(model$plates, `[[`, character(1), "name")
  stats::setNames(lapply(nn, function(v)
    pn[vapply(model$plates, function(p) v %in% p$members, logical(1))]),
    nn)
}

# Is plate `a` nested (at any depth) inside plate `b`?
.umg_plate_within <- function(model, a, b) {
  pn <- vapply(model$plates, `[[`, character(1), "name")
  cur <- model$plates[[match(a, pn)]]
  guard <- 0L   # nesting is acyclic by W5, but never loop forever
  while (!is.null(cur$parent) && guard <= length(pn)) {
    if (identical(cur$parent, b)) return(TRUE)
    cur <- model$plates[[match(cur$parent, pn)]]
    guard <- guard + 1L
  }
  FALSE
}

# Strip TeX `$...$` delimiters and backslashes for display.
.umg_plain <- function(x) {
  x <- gsub("\\$", "", x)
  x <- gsub("\\\\", "", x)
  x
}

# Does a dist annotation fix the variance to a numeric value? TRUE for
# annotations such as "N(0, 1)", "var = 1", "var = 0", "resid var = 1";
# FALSE for symbolic variances ("N(0, psi)", "var = free") and NULL.
# Shared by umg_check_scaling() and umg_count_parameters() so the
# scaling report and the counting rule cannot drift apart.
.umg_fixed_var_dist <- function(dist) {
  if (is.null(dist)) return(FALSE)
  grepl("var *= *[0-9][0-9.]*", dist) ||
    grepl("N\\([^,()]+, *[0-9][0-9.]* *\\)", dist)
}

# Mean-structure annotation of a vertex: the value of a "mean = ..."
# clause in its annot field ("free", "fixed", or a number given as a
# character string), or NULL when the vertex carries none. Written by
# umg_from_lavaan() from the "~1" rows of a parameter table; read by
# umg_to_lavaan() (intercept lines) and umg_count_parameters()
# (meanstructure = TRUE).
.umg_mean_annot <- function(node) {
  a <- node$annot
  if (is.null(a)) return(NULL)
  m <- regmatches(a, regexec("(^|; *)mean *= *([^;]+)", a))[[1]]
  if (!length(m)) return(NULL)
  trimws(m[3L])
}

# Append a clause to an annotation string ("; "-separated), without
# duplicating a clause that is already present.
.umg_annot_add <- function(annot, clause) {
  if (is.null(annot) || !nzchar(annot)) return(clause)
  if (clause %in% trimws(strsplit(annot, ";", fixed = TRUE)[[1]]))
    return(annot)
  paste(annot, clause, sep = "; ")
}

# Number of free mean-structure parameters read from a diagram. When
# every random vertex carries a mean annotation, count the vertices
# annotated "mean = free"; otherwise apply the growth-model convention
# (indicators of latent factors have zero intercepts): one mean per
# latent source vertex plus one intercept per observed vertex that is
# not regressed on a latent vertex. See ?umg_count_parameters.
.umg_free_means <- function(model) {
  nodes <- model$nodes
  rv <- Filter(function(v) v$role == "rv", nodes)
  ann <- lapply(rv, .umg_mean_annot)
  if (length(rv) && !any(vapply(ann, is.null, logical(1))))
    return(sum(vapply(ann, function(a) identical(a, "free"), logical(1))))
  parents <- .umg_parents(model)   # directed (dep/det/mix) parents
  is_latent <- function(v) !nodes[[v]]$observed && nodes[[v]]$role == "rv"
  sum(vapply(names(rv), function(v) {
    pa <- parents[[v]]
    if (is_latent(v)) length(pa) == 0L            # latent source: free mean
    else !any(vapply(pa, is_latent, logical(1)))  # observed, not an indicator
  }, logical(1)))
}

# Default label for a vertex name, used by motif builders.
.umg_default_label <- function(name, subscript = "i") {
  paste0("$", name, "_", subscript, "$")
}

# A safe display label (falls back to the vertex name).
.umg_disp <- function(node) {
  lab <- node$label %||% node$name
  .umg_plain(lab)
}

# Coerce a theme argument: pass umg_theme objects through, interpret a
# character scalar as a style name, and reject anything else rather
# than silently substituting the default.
.umg_as_theme <- function(theme) {
  if (inherits(theme, "umg_theme")) return(theme)
  if (is.character(theme) && length(theme) == 1L)
    return(umg_theme(theme))
  stop("'theme' must be a umg_theme object (see umg_theme()) or a ",
       "style name (\"journal\", \"slide\", \"cb\").", call. = FALSE)
}
