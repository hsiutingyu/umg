# Tests for tabular export, summary, and lavaan syntax generation.

test_that("as.data.frame returns edge and vertex tables", {
  m <- umg_factor("F", paste0("y", 1:3))
  e <- as.data.frame(m)
  expect_s3_class(e, "data.frame")
  expect_identical(names(e), c("from", "to", "kind", "label", "fixed"))
  expect_equal(nrow(e), length(m$edges))
  expect_true(is.numeric(e$fixed))
  expect_equal(e$fixed[e$from == "F" & e$to == "y1"], 1)

  v <- as.data.frame(m, what = "vertices")
  expect_identical(names(v),
    c("name", "label", "observed", "support", "role", "dist", "fill", "annot"))
  expect_equal(nrow(v), length(m$nodes))
  expect_true(is.logical(v$observed))
})

test_that("as.data.frame handles an edgeless model", {
  m <- umg_model(
    nodes = list(umg_node("a", observed = TRUE, dist = "free")),
    edges = list(), plates = list())
  e <- as.data.frame(m)
  expect_equal(nrow(e), 0L)
  expect_identical(names(e), c("from", "to", "kind", "label", "fixed"))
})

test_that("summary.umg reports structure and counting-rule df", {
  m <- umg_sem(list(F1 = paste0("y", 1:3), F2 = paste0("y", 4:6)),
               structural = list(c("F1", "F2")))
  s <- summary(m)
  expect_s3_class(s, "summary.umg")
  expect_equal(s$n_latent, 2L)
  expect_equal(s$n_observed, 6L)
  expect_equal(s$data_information, 21)  # 6*7/2
  expect_output(print(s), "Counting rule")
})

test_that("umg_to_lavaan writes loadings, regressions, and covariances", {
  m <- umg_sem(list(F1 = paste0("y", 1:3), F2 = paste0("y", 4:6)),
               structural = list(c("F1", "F2")),
               covariances = list(c("y1", "y2")))
  syn <- suppressMessages(umg_to_lavaan(m))
  expect_type(syn, "character")
  expect_match(syn, "F1 =~ 1\\*y1 \\+ y2 \\+ y3")
  expect_match(syn, "F2 ~ F1")
  expect_match(syn, "y1 ~~ y2")
})

test_that("umg_to_lavaan classifies MIMIC edges correctly", {
  m <- umg_mimic(c("z1", "z2"), paste0("y", 1:3))
  syn <- suppressMessages(umg_to_lavaan(m))
  expect_match(syn, "F =~ 1\\*y1")          # reflective side is a loading
  expect_match(syn, "F ~ z1 \\+ z2")        # formative causes are regressions
})

test_that("umg_to_lavaan warns on mixing/deterministic edges", {
  gm <- umg_mixture(umg_growth(4), targets = c("I", "S"))
  expect_warning(umg_to_lavaan(gm), "mixing")
})

test_that("umg_to_lavaan output is parseable by lavaan", {
  skip_if_not_installed("lavaan")
  m <- umg_sem(list(F1 = paste0("y", 1:3), F2 = paste0("y", 4:6)),
               structural = list(c("F1", "F2")))
  syn <- suppressMessages(umg_to_lavaan(m))
  pt <- lavaan::lavaanify(syn)
  expect_s3_class(pt, "data.frame")
  expect_true(any(pt$op == "=~"))
  expect_true(any(pt$op == "~"))
})
