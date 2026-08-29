# Tests for fitted-object converters. Most are skipped unless the
# relevant suggested package is installed; a few run on inputs that
# need no external package.

test_that("umg_from_mirt builds a structural sketch from an integer", {
  m <- umg_from_mirt(1L, "2PL")
  expect_s3_class(m, "umg")
  expect_true(umg_validate(m))
  expect_true(all(c("theta1", "u", "a", "b") %in% names(m$nodes)))

  m3 <- umg_from_mirt(1L, "3PL")
  expect_true("g" %in% names(m3$nodes))
})

test_that("umg_from_qgraph accepts a weights matrix", {
  set.seed(1)
  W <- matrix(0, 4, 4)
  W[1, 2] <- W[2, 1] <- 0.4
  W[3, 4] <- W[4, 3] <- 0.5
  rownames(W) <- colnames(W) <- paste0("v", 1:4)
  m <- umg_from_qgraph(W, threshold = 0.1)
  expect_s3_class(m, "umg")
  expect_true(umg_validate(m))
  n_cov <- sum(vapply(m$edges, function(e) e$kind == "cov", logical(1)))
  expect_equal(n_cov, 2)
})

test_that("umg_from_lavaan translates a model string", {
  skip_if_not_installed("lavaan")
  syntax <- "F =~ y1 + y2 + y3"
  m <- umg_from_lavaan(syntax)
  expect_s3_class(m, "umg")
  expect_true("F" %in% names(m$nodes))
})

test_that("umg_from_lmer parses a mixed-model formula", {
  skip_if_not_installed("lme4")
  m <- umg_from_lmer(Reaction ~ Days + (Days | Subject))
  expect_s3_class(m, "umg")
  expect_true(umg_validate(m))
  expect_equal(length(m$plates), 2L)
})

test_that("umg_from_brms accepts a formula and marks priors", {
  skip_if_not_installed("lme4")
  m <- umg_from_brms(Reaction ~ Days + (Days | Subject))
  expect_s3_class(m, "umg")
  pars_prior <- vapply(m$nodes, function(v)
    identical(v$dist, "prior"), logical(1))
  expect_true(any(pars_prior))
})
