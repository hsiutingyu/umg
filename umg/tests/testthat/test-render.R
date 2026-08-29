# Tests for the ggplot2 backend and the duality scaffolds. These are
# skipped unless ggplot2 (and, for DOT rendering, DiagrammeR) are
# installed.

test_that("umg_ggplot returns a ggplot object", {
  skip_if_not_installed("ggplot2")
  g <- umg_ggplot(umg_factor("F", paste0("y", 1:4)))
  expect_s3_class(g, "ggplot")
})

test_that("autoplot.umg dispatches to umg_ggplot", {
  skip_if_not_installed("ggplot2")
  g <- ggplot2::autoplot(umg_irt("2PL"))
  expect_s3_class(g, "ggplot")
})

test_that("umg_caterpillar builds, with and without standard errors", {
  skip_if_not_installed("ggplot2")
  set.seed(1)
  g <- umg_caterpillar(rnorm(15), se = runif(15, 0.2, 0.5))
  expect_s3_class(g, "ggplot")
  # Force the build so deferred aesthetics (the error-bar bounds) are
  # actually evaluated; constructing the object alone does not.
  expect_no_error(ggplot2::ggplot_build(g))
  g2 <- umg_caterpillar(rnorm(10))
  expect_no_error(ggplot2::ggplot_build(g2))
})

test_that("umg_eda_scaffold returns named ggplot scaffolds", {
  skip_if_not_installed("ggplot2")
  set.seed(1)
  d <- as.data.frame(matrix(rnorm(40 * 4), ncol = 4,
                            dimnames = list(NULL, paste0("y", 1:4))))
  out <- umg_eda_scaffold(umg_factor("F", paste0("y", 1:4)), d)
  expect_type(out, "list")
  expect_true(any(grepl("^score_", names(out))))
})

test_that("umg_render_dot returns a grViz widget", {
  skip_if_not_installed("DiagrammeR")
  w <- umg_render_dot(umg_factor("F", paste0("y", 1:3)))
  expect_s3_class(w, "htmlwidget")
})
