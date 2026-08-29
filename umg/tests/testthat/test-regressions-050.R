# Regression tests for the defects fixed in the 0.4.0 -> 0.5.0
# revision. Each test encodes a confirmed failure of 0.4.0, so that
# none of the fixes can regress silently.

# ----- d-separation: exact on dense graphs -------------------------

test_that("umg_dsep is exact on dense graphs (no path-enumeration cap)", {
  # 0.4.0 enumerated skeleton paths with a silent 20000-path cap and
  # returned TRUE for directly connected vertices in a 10-node
  # saturated network
  m <- umg_network(paste0("x", 1:10))
  expect_false(umg_dsep(m, "x1", "x10"))
})

test_that("umg_dsep rejects degenerate queries", {
  m <- umg_mediation(direct = FALSE)
  expect_error(umg_dsep(m, "X", "X"), "distinct")
  expect_error(umg_dsep(m, "X", "Y", given = "X"), "distinct")
})

# ----- counting rule: fixed variances and categorical models --------

test_that("fixed variances are subtracted regardless of vertex type", {
  # observed vertex with a fixed variance (e.g. lavaan y1 ~~ 0*y1)
  nodes <- list(umg_node("F", observed = FALSE, dist = "N(0, psi)"),
                umg_node("y1", observed = TRUE, dist = "var = 0"),
                umg_node("y2", observed = TRUE),
                umg_node("y3", observed = TRUE),
                umg_node("y4", observed = TRUE))
  edges <- list(umg_edge("F", "y1", "dep", fixed = 1),
                umg_edge("F", "y2", "dep", label = "$\\lambda_2$"),
                umg_edge("F", "y3", "dep", label = "$\\lambda_3$"),
                umg_edge("F", "y4", "dep", label = "$\\lambda_4$"))
  m <- umg_model(nodes, edges,
                 list(umg_plate("p", c("F", paste0("y", 1:4)), "i")))
  cnt <- umg_count_parameters(m)
  # 3 free loadings + 4 variances (F, y2, y3, y4; y1 fixed) = 7
  expect_equal(cnt$free_total, 7)
  expect_equal(cnt$df, 10 - 7)
})

test_that("a marker-scaled latent with an additionally fixed variance is
           not double counted as free", {
  nodes <- list(umg_node("F", observed = FALSE, dist = "N(0, 1)"),
                umg_node("y1", observed = TRUE),
                umg_node("y2", observed = TRUE),
                umg_node("y3", observed = TRUE))
  edges <- list(umg_edge("F", "y1", "dep", fixed = 1),
                umg_edge("F", "y2", "dep", label = "$\\lambda_2$"),
                umg_edge("F", "y3", "dep", label = "$\\lambda_3$"))
  m <- umg_model(nodes, edges,
                 list(umg_plate("p", c("F", paste0("y", 1:3)), "i")))
  cnt <- umg_count_parameters(m)
  # scaling reports the marker first, but the fixed variance must
  # still be excluded from the variance count: 2 loadings + 3
  # residual variances = 5
  expect_equal(cnt$free_total, 5)
})

test_that("the counting rule declares itself inapplicable for
           categorical models", {
  expect_warning(cnt <- umg_count_parameters(umg_irt("2PL")),
                 "categorical")
  expect_false(cnt$applicable)
  expect_true(is.na(cnt$df))
  expect_warning(id <- umg_identify(umg_lca(paste0("u", 1:4))),
                 "categorical")
  expect_output(print(id), "not applicable")
})

# ----- implied CIs: testability of the conditioning set -------------

test_that("umg_implied_ci with observed_only excludes latent
           conditioning sets", {
  ci <- umg_implied_ci(umg_factor("F", paste0("y", 1:4)))
  expect_equal(nrow(ci), 0L)  # all statements condition on latent F
  ci_all <- umg_implied_ci(umg_factor("F", paste0("y", 1:4)),
                           observed_only = FALSE)
  expect_gt(nrow(ci_all), 0L)
})

# ----- motifs: statistical content ----------------------------------

test_that("umg_riclpm encodes the Hamaker et al. (2015) RI-CLPM", {
  m <- umg_riclpm(waves = 4)
  cnt <- umg_count_parameters(m)
  # 12 lagged paths + 5 covariances (RI, t=1, and 3 innovation
  # covariances) + 10 variances (2 RI + 8 within; observed residuals
  # are fixed at 0 by the exact decomposition) = 27; p = 8 -> df = 9
  expect_equal(cnt$free_total, 27)
  expect_equal(cnt$df, 9)
  # wave-specific innovation covariances present at t = 2, 3, 4
  n_wcov <- sum(vapply(m$edges, function(e)
    e$kind == "cov" && grepl("^w", e$from), logical(1)))
  expect_equal(n_wcov, 4)  # t = 1 initial + 3 innovation covariances
})

test_that("umg_sem variance scaling fixes every factor's scale", {
  m <- umg_sem(measurement = list(F1 = paste0("y", 1:3),
                                  F2 = paste0("y", 4:6)),
               structural = list(c("F1", "F2")),
               scaling = "variance")
  sc <- umg_check_scaling(m)
  expect_true(all(sc$scaled))
})

test_that("umg_secondorder does not double-fix the general factor", {
  m <- umg_secondorder(list(F1 = paste0("y", 1:3),
                            F2 = paste0("y", 4:6),
                            F3 = paste0("y", 7:9)))
  sc <- umg_check_scaling(m)
  expect_true(all(sc$scaled))
  # g is scaled by the fixed first second-order loading only; its
  # variance stays free
  expect_false(umg:::.umg_fixed_var_dist(m$nodes[["g"]]$dist))
})

test_that("umg_mixture keeps the mixing proportion outside the plate", {
  gm <- umg_mixture(umg_growth(4), targets = c("I", "S"))
  members <- gm$plates[[1]]$members
  expect_true("c" %in% members)
  expect_false("pi" %in% members)
})

test_that("umg_mixture rejects an unknown plate name", {
  expect_error(umg_mixture(umg_growth(4), c("I", "S"), plate = "nope"),
               "no plate named")
})

test_that("umg_network reads lower-triangular adjacency matrices", {
  A <- matrix(0, 3, 3)
  A[2, 1] <- 1; A[3, 2] <- 1   # lower triangle only
  m <- umg_network(paste0("x", 1:3), edges_mat = A)
  expect_equal(length(m$edges), 2L)
})

test_that("umg_factor labels free loadings as documented", {
  m <- umg_factor("F", paste0("y", 1:3),
                  loadings = c("$l_2$", "$l_3$"))
  labs <- vapply(m$edges, `[[`, character(1), "label")
  expect_identical(labs[2:3], c("$l_2$", "$l_3$"))
  expect_error(umg_factor("F", paste0("y", 1:3), loadings = "$l$"),
               "length")
})

test_that("umg_dcm warns on a probably transposed Q-matrix and draws
           attribute covariances", {
  Q_jk <- matrix(1, 6, 3)   # items-by-attributes orientation
  expect_warning(umg_dcm(Q_jk), "t\\(Q\\)")
  m <- umg_dcm(rbind(c(1, 1, 0), c(0, 1, 1)))
  n_cov <- sum(vapply(m$edges, function(e) e$kind == "cov", logical(1)))
  expect_equal(n_cov, 1L)   # alpha1 -- alpha2
  m0 <- umg_dcm(rbind(c(1, 1, 0), c(0, 1, 1)), attr_cov = FALSE)
  expect_equal(sum(vapply(m0$edges, function(e)
    e$kind == "cov", logical(1))), 0L)
})

# ----- converters ---------------------------------------------------

test_that("multi-group lavaan fits are not duplicated", {
  skip_if_not_installed("lavaan")
  hs <- "visual =~ x1 + x2 + x3\n textual =~ x4 + x5 + x6"
  fit1 <- lavaan::cfa(hs, data = lavaan::HolzingerSwineford1939)
  suppressMessages(
    fit2 <- lavaan::cfa(hs, data = lavaan::HolzingerSwineford1939,
                        group = "school"))
  m1 <- umg_from_lavaan(fit1)
  expect_message(m2 <- umg_from_lavaan(fit2), "multi-group")
  expect_equal(length(m2$edges), length(m1$edges))
})

test_that("ordinal lavaan indicators are typed categorical", {
  skip_if_not_installed("lavaan")
  syntax <- "F =~ u1 + u2 + u3\nu1 | t1\nu2 | t1\nu3 | t1"
  expect_message(m <- umg_from_lavaan(syntax), "ordinal")
  expect_identical(m$nodes[["u1"]]$support, "categorical")
  expect_match(m$nodes[["u1"]]$annot, "threshold")
})

test_that("umg_from_qgraph symmetrises asymmetric matrices with a
           warning instead of dropping edges", {
  W <- matrix(0, 3, 3)
  W[2, 1] <- 0.4   # A -> B stored in the lower triangle
  W[1, 3] <- 0.5   # A -> C stored in the upper triangle
  expect_warning(m <- umg_from_qgraph(W), "asymmetric")
  expect_equal(length(m$edges), 2L)
})

test_that("umg_from_lmer warns when the grouping column is missing", {
  skip_if_not_installed("lme4")
  d <- data.frame(Reaction = 1:4, Days = 1:4)
  expect_warning(umg_from_lmer(Reaction ~ Days + (Days | Subject),
                               data = d), "not found")
})

test_that("umg_from_mirt reads the item type from a fitted object", {
  skip_if_not_installed("mirt")
  set.seed(101)
  dat <- mirt::simdata(a = matrix(rlnorm(6, 0.2, 0.2)),
                       d = matrix(seq(-1, 1, length.out = 6)),
                       N = 300, itemtype = "2PL")
  fit <- mirt::mirt(dat, 1, itemtype = "Rasch", verbose = FALSE)
  m <- umg_from_mirt(fit)
  expect_false("a" %in% names(m$nodes))   # Rasch -> 1PL: no slopes
})

# ----- rendering ----------------------------------------------------

test_that("edge labels may be NULL without crashing any backend", {
  e <- umg_edge("F", "y1", "dep", label = NULL)
  expect_identical(e$label, "")
  expect_error(umg_edge("F", "y1", "dep", label = NA_character_),
               "character scalar")
  expect_error(umg_edge("F", "y1", "dep", fixed = NA), "fixed")
})

test_that("umg_to_tikz preserves large coordinates exactly", {
  m <- umg_factor("F", paste0("y", 1:2))
  m <- umg_layout(m, coords = data.frame(name = "F", x = 1000.55, y = 0))
  code <- umg_to_tikz(m)
  expect_true(any(grepl("1000.55", code, fixed = TRUE)))
})

test_that("invalid theme arguments error; style names are accepted", {
  m <- umg_factor("F", paste0("y", 1:3))
  expect_error(umg_to_dot(m, theme = 42), "umg_theme")
  expect_type(umg_to_dot(m, theme = "cb"), "character")
})

test_that("umg_theme rejects NULL elements and drops unknown ones", {
  expect_error(umg_theme(node_r = NULL), "NULL")
  expect_warning(th <- umg_theme(nonsense = 1), "ignored")
  expect_null(th$nonsense)
})

test_that("the ggplot backend distinguishes mix edges and shrinks
           segment endpoints to the node boundary", {
  skip_if_not_installed("ggplot2")
  gm <- umg_mixture(umg_growth(4), targets = c("I", "S"))
  g <- umg_ggplot(gm)
  arrows <- Filter(Negate(is.null),
                   lapply(g$layers, function(l) l$geom_params$arrow))
  types <- unique(vapply(arrows, function(a) a$type, integer(1)))
  expect_length(types, 2L)   # closed (dep/cov) and open (mix)
  expect_no_error(ggplot2::ggplot_build(g))
  # endpoints are pulled off the vertex centres so arrowheads show
  gl <- umg_layout(gm)$layout$vertices
  seg_layer <- Filter(function(l)
    inherits(l$geom, "GeomSegment"), g$layers)[[1]]
  d <- seg_layer$data
  ends <- paste(round(d$xend, 6), round(d$yend, 6))
  ctrs <- paste(round(gl$x, 6), round(gl$y, 6))
  expect_false(any(ends %in% ctrs))
})