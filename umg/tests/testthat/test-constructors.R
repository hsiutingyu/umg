# Tests for the core constructors.

test_that("umg_node sets typed fields and defaults", {
  n <- umg_node("eta", observed = FALSE)
  expect_s3_class(n, "umg_node")
  expect_false(n$observed)
  expect_identical(n$support, "continuous")
  expect_identical(n$role, "rv")
  expect_null(n$fill)

  n2 <- umg_node("y", observed = TRUE, support = "categorical",
                 role = "rv", dist = "Bernoulli(p)", fill = "grey60",
                 annot = "rev")
  expect_true(n2$observed)
  expect_identical(n2$support, "categorical")
  expect_identical(n2$fill, "grey60")
  expect_identical(n2$annot, "rev")
})

test_that("umg_node validates argument types", {
  expect_error(umg_node(123))
  expect_error(umg_node("x", support = "nonsense"))
  expect_error(umg_node("x", role = "nonsense"))
  expect_error(umg_node("x", fill = 1))
})

test_that("umg_edge records kind, label, fixed", {
  e <- umg_edge("a", "b", "dep", fixed = 1)
  expect_s3_class(e, "umg_edge")
  expect_identical(e$kind, "dep")
  expect_equal(e$fixed, 1)
  expect_error(umg_edge("a", "b", "nonsense"))
})

test_that("umg_plate stores membership and index", {
  p <- umg_plate("person", c("a", "b"), "i = 1, ..., N")
  expect_s3_class(p, "umg_plate")
  expect_identical(p$members, c("a", "b"))
  expect_error(umg_plate("p", character(0), "i"))
})

test_that("umg_model assembles, names nodes, and rejects duplicates", {
  m <- umg_factor("F", paste0("y", 1:3))
  expect_s3_class(m, "umg")
  expect_true(all(c("F", "y1", "y2", "y3") %in% names(m$nodes)))

  dup <- list(umg_node("a", dist = "N(0,1)"), umg_node("a", dist = "N(0,1)"))
  expect_error(umg_model(dup, list(), list()))
})

test_that("print.umg returns its argument invisibly", {
  m <- umg_factor("F", paste0("y", 1:3))
  expect_invisible(print(m))
  expect_output(print(m), "Unified Model Graph")
})
