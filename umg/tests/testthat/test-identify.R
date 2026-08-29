# Tests for the identification tooling.

test_that("umg_check_scaling detects marker loadings", {
  sc <- umg_check_scaling(umg_factor("F", paste0("y", 1:4)))
  expect_s3_class(sc, "data.frame")
  expect_true(sc$scaled[sc$vertex == "F"])
  expect_identical(sc$via[sc$vertex == "F"], "marker loading")
})

test_that("umg_check_scaling detects fixed-variance scaling", {
  m <- umg_esem("F1", paste0("y", 1:4))  # variance fixed to 1
  sc <- umg_check_scaling(m)
  expect_identical(sc$via[sc$vertex == "F1"], "fixed variance")
})

test_that("umg_count_parameters returns a counting-rule breakdown", {
  cnt <- umg_count_parameters(umg_factor("F", paste0("y", 1:6)))
  expect_named(cnt, c("data_information", "free", "free_total", "df",
                      "applicable"))
  expect_equal(cnt$data_information, 6 * 7 / 2)
  expect_true(is.numeric(cnt$df))
  expect_true(cnt$applicable)
})

test_that("umg_dsep reads conditional independence off mediation", {
  m <- umg_mediation(direct = FALSE)
  expect_false(umg_dsep(m, "X", "Y"))
  expect_true(umg_dsep(m, "X", "Y", given = "M"))
})

test_that("collider conditioning opens a path", {
  # X -> C <- Y : X and Y marginally independent, dependent given C
  nodes <- list(umg_node("X", observed = TRUE, dist = "free"),
                umg_node("Y", observed = TRUE, dist = "free"),
                umg_node("C", observed = TRUE))
  edges <- list(umg_edge("X", "C", "dep"), umg_edge("Y", "C", "dep"))
  m <- umg_model(nodes, edges, list(umg_plate("p", c("X", "Y", "C"), "i")))
  expect_true(umg_dsep(m, "X", "Y"))
  expect_false(umg_dsep(m, "X", "Y", given = "C"))
})

test_that("umg_implied_ci returns a data frame of statements", {
  ci <- umg_implied_ci(umg_mediation(direct = FALSE))
  expect_s3_class(ci, "data.frame")
  expect_true(all(c("x", "y", "given") %in% names(ci)))
})

test_that("umg_labelswitching flags latent classes", {
  ls <- umg_labelswitching(umg_mixture(umg_growth(4), c("I", "S")))
  expect_true("c" %in% ls)
  expect_length(umg_labelswitching(umg_factor("F", paste0("y", 1:3))), 0)
})

test_that("umg_identify returns a printable summary", {
  id <- umg_identify(umg_factor("F", paste0("y", 1:6)))
  expect_s3_class(id, "umg_identification")
  expect_output(print(id), "identification summary")
})
