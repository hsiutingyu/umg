# ============================================================
# Title:  Model-data duality: EDA display scaffolds from UMG motifs
# File:   duality.R (package umg)
# Author: H.-T. Yu
# Date:   2026-06-12
# ============================================================

#' Generate exploratory display scaffolds from a UMG
#'
#' Implements the model-data duality of the UMG grammar (article,
#' Table 3): each motif in the diagram induces a canonical
#' exploratory display. Given a UMG and a data frame, the function
#' returns a named list of ggplot objects: faceted panels for plates
#' whose index variable is found in the data, spaghetti plots for
#' random-coefficient motifs, scatter plots for dep edges between
#' observed continuous vertices, latent-score distributions, mixture
#' densities, empirical response curves, and residual correlation heat
#' maps. The scaffolds are intentionally minimal; they are starting
#' points for exploration, not finished graphics.
#'
#' @param model An object of class `umg`.
#' @param data A data frame containing the observed vertices.
#' @param id Optional name of the cluster identifier column for
#'   spaghetti plots.
#' @param time Optional name of the within-cluster covariate (x axis
#'   for spaghetti plots).
#' @return A named list of ggplot objects (possibly empty).
#' @examples
#' \dontrun{
#' m <- umg_factor("F", paste0("y", 1:4))
#' d <- as.data.frame(matrix(rnorm(400), ncol = 4,
#'                           dimnames = list(NULL, paste0("y", 1:4))))
#' umg_eda_scaffold(m, d)
#' }
#' @export
umg_eda_scaffold <- function(model, data, id = NULL, time = NULL) {
  .umg_require("ggplot2", "umg_eda_scaffold")
  stopifnot(inherits(model, "umg"), is.data.frame(data))
  out <- list()

  obs <- names(Filter(function(v) v$observed && v$role == "rv",
                      model$nodes))
  obs_in_data <- intersect(obs, names(data))

  # ----- dep edges between observed continuous vertices -----------
  for (e in model$edges) {
    if (e$kind != "dep") next
    if (!(e$from %in% obs_in_data && e$to %in% obs_in_data)) next
    nm <- paste0("scatter_", e$from, "_", e$to)
    out[[nm]] <- ggplot2::ggplot(
      data, ggplot2::aes(x = .data[[e$from]], y = .data[[e$to]])) +
      ggplot2::geom_point(alpha = 0.5) +
      ggplot2::geom_smooth(method = "lm", formula = y ~ x,
                           se = TRUE, linewidth = 0.6) +
      ggplot2::labs(title = paste0("dep edge: ", e$from,
                                   " -> ", e$to)) +
      ggplot2::theme_minimal()
  }

  # ----- random-coefficient motif: spaghetti plot ------------------
  has_random_coef <- any(vapply(model$nodes, function(v) {
    !v$observed && v$role == "rv" && v$support == "continuous"
  }, logical(1))) && length(model$plates) >= 2L
  if (has_random_coef && !is.null(id) && !is.null(time) &&
      all(c(id, time) %in% names(data)) && length(obs_in_data)) {
    yvar <- obs_in_data[1L]
    out[["spaghetti"]] <- ggplot2::ggplot(
      data, ggplot2::aes(x = .data[[time]], y = .data[[yvar]],
                         group = .data[[id]])) +
      ggplot2::geom_line(alpha = 0.4) +
      ggplot2::geom_smooth(ggplot2::aes(group = NULL),
                           method = "lm", formula = y ~ x,
                           se = FALSE, linewidth = 1) +
      ggplot2::labs(title = "Random-coefficient motif: cluster trajectories") +
      ggplot2::theme_minimal()
    out[["facets"]] <- ggplot2::ggplot(
      data, ggplot2::aes(x = .data[[time]], y = .data[[yvar]])) +
      ggplot2::geom_point(size = 0.7) +
      ggplot2::geom_smooth(method = "lm", formula = y ~ x,
                           se = FALSE, linewidth = 0.5) +
      ggplot2::facet_wrap(stats::as.formula(paste("~", id))) +
      ggplot2::labs(title = "Plate motif: trellis over cluster index") +
      ggplot2::theme_minimal()
  }

  # ----- latent continuous vertex: score distribution -------------
  # Each latent continuous factor implies a distribution of estimated
  # scores; in the absence of factor scores, the mean of its observed
  # children is the canonical exploratory proxy.
  for (v in names(model$nodes)) {
    nd <- model$nodes[[v]]
    if (nd$observed || nd$role != "rv" || nd$support != "continuous") next
    children <- vapply(Filter(function(e)
      e$kind == "dep" && e$from == v, model$edges),
      `[[`, character(1), "to")
    ind <- intersect(children, obs_in_data)
    if (length(ind) < 2L) next
    score <- rowMeans(data[, ind, drop = FALSE], na.rm = TRUE)
    df_s <- data.frame(score = score)
    out[[paste0("score_", v)]] <- ggplot2::ggplot(
      df_s, ggplot2::aes(x = .data[["score"]])) +
      ggplot2::geom_histogram(ggplot2::aes(y = ggplot2::after_stat(density)),
                              bins = 30, fill = "grey80", colour = "white") +
      ggplot2::geom_density(linewidth = 0.7) +
      ggplot2::labs(title = paste0("Latent vertex '", v,
                                   "': mean-score distribution"),
                    x = paste0("mean of ", paste(ind, collapse = ", "))) +
      ggplot2::theme_minimal()
  }

  # ----- latent categorical vertex: mixture density ---------------
  # A latent class vertex implies a mixture density whose modes reveal
  # whether the classes are separable.
  has_class <- any(vapply(model$nodes, function(v)
    !v$observed && v$role == "rv" && v$support == "categorical",
    logical(1)))
  cont_obs <- intersect(
    names(Filter(function(v) v$observed && v$support == "continuous",
                 model$nodes)), names(data))
  if (has_class && length(cont_obs)) {
    yv <- cont_obs[1L]
    out[["mixture_density"]] <- ggplot2::ggplot(
      data, ggplot2::aes(x = .data[[yv]])) +
      ggplot2::geom_density(fill = "grey85", linewidth = 0.7) +
      ggplot2::labs(title = "Latent class vertex: marginal density (check for modes)",
                    x = yv) +
      ggplot2::theme_minimal()
  }

  # ----- categorical child: empirical response curve --------------
  # A dependence with a categorical outcome implies the empirical
  # response curve of the link function.
  for (e in model$edges) {
    if (e$kind != "dep") next
    from <- model$nodes[[e$from]]; to <- model$nodes[[e$to]]
    if (is.null(from) || is.null(to)) next
    if (!(from$observed && from$support == "continuous" &&
          to$observed && to$support == "categorical")) next
    if (!all(c(e$from, e$to) %in% names(data))) next
    out[[paste0("response_", e$from, "_", e$to)]] <- ggplot2::ggplot(
      data, ggplot2::aes(x = .data[[e$from]],
                         y = as.numeric(.data[[e$to]]))) +
      ggplot2::geom_jitter(height = 0.03, alpha = 0.4, size = 0.7) +
      ggplot2::geom_smooth(method = "glm", formula = y ~ x,
                           method.args = list(family = "binomial"),
                           se = TRUE, linewidth = 0.6) +
      ggplot2::labs(title = paste0("Empirical response curve: ",
                                   e$to, " on ", e$from)) +
      ggplot2::theme_minimal()
  }

  # ----- covariance block: residual correlation heat map ----------
  cov_vars <- unique(unlist(lapply(Filter(function(e) e$kind == "cov",
                                          model$edges),
                                   function(e) c(e$from, e$to))))
  heat_vars <- intersect(cov_vars, obs_in_data)
  if (length(heat_vars) < 3L) heat_vars <- obs_in_data  # fall back
  if (length(heat_vars) >= 3L) {
    cm <- stats::cor(data[, heat_vars, drop = FALSE],
                     use = "pairwise.complete.obs")
    grid <- expand.grid(Var1 = rownames(cm), Var2 = colnames(cm),
                        stringsAsFactors = FALSE)
    grid$r <- mapply(function(a, b) cm[a, b], grid$Var1, grid$Var2)
    out[["resid_heatmap"]] <- ggplot2::ggplot(
      grid, ggplot2::aes(x = .data[["Var1"]], y = .data[["Var2"]],
                         fill = .data[["r"]])) +
      ggplot2::geom_tile() +
      ggplot2::scale_fill_gradient2(limits = c(-1, 1)) +
      ggplot2::labs(title = "Covariance block: observed correlation heat map",
                    x = NULL, y = NULL, fill = "r") +
      ggplot2::theme_minimal() +
      ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45,
                                                         hjust = 1))
  }

  out
}

#' Caterpillar (shrinkage) plot of cluster-level estimates
#'
#' Renders the caterpillar plot implied by a random-coefficient
#' vertex: cluster-level estimates ordered by value with optional
#' uncertainty intervals, the canonical display for inspecting
#' between-cluster variation and shrinkage. The input is the estimated
#' deviations, which the modelling package supplies after fitting;
#' the diagram object names the display, this function draws it.
#'
#' @param estimates A numeric vector of cluster-level estimates, or a
#'   data frame with a column `estimate` and optionally `se` and
#'   `group`.
#' @param se Optional numeric vector of standard errors (used when
#'   `estimates` is a numeric vector).
#' @param level Confidence level for the interval (default `0.95`).
#' @param title Plot title.
#' @return A ggplot object.
#' @examples
#' set.seed(1)
#' if (requireNamespace("ggplot2", quietly = TRUE))
#'   umg_caterpillar(rnorm(20), se = runif(20, 0.2, 0.5))
#' @export
umg_caterpillar <- function(estimates, se = NULL, level = 0.95,
                            title = "Caterpillar plot: cluster estimates") {
  .umg_require("ggplot2", "umg_caterpillar")
  if (is.data.frame(estimates)) {
    df <- estimates
    if (is.null(df$estimate))
      stop("Data frame input needs an 'estimate' column.", call. = FALSE)
    if (is.null(df$group)) df$group <- seq_len(nrow(df))
  } else {
    df <- data.frame(estimate = as.numeric(estimates),
                     group = seq_along(estimates))
    if (!is.null(se)) df$se <- se
  }
  z <- stats::qnorm(1 - (1 - level) / 2)
  df <- df[order(df$estimate), , drop = FALSE]
  df$rank <- seq_len(nrow(df))
  # Compute interval bounds before constructing the ggplot so that the
  # error-bar layer can resolve `lo`/`hi` from the plot data.
  has_se <- !is.null(df$se)
  if (has_se) {
    df$lo <- df$estimate - z * df$se
    df$hi <- df$estimate + z * df$se
  }
  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data[["rank"]],
                                        y = .data[["estimate"]]))
  if (has_se) {
    p <- p + ggplot2::geom_errorbar(
      ggplot2::aes(ymin = .data[["lo"]], ymax = .data[["hi"]]),
      width = 0, colour = "grey60")
  }
  p + ggplot2::geom_point(size = 1.2) +
    ggplot2::geom_hline(yintercept = 0, linetype = 2, colour = "grey50") +
    ggplot2::labs(title = title, x = "cluster (ordered)",
                  y = "estimate") +
    ggplot2::theme_minimal()
}
