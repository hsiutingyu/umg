# Tests for the well-formedness rules W1-W6.

test_that("a valid model passes validation", {
  m <- umg_factor("F", paste0("y", 1:3))
  expect_true(umg_validate(m))
})

test_that("W1: directed cycles are rejected", {
  nodes <- list(umg_node("a", dist = "N(0,1)"),
                umg_node("b", dist = "N(0,1)"))
  edges <- list(umg_edge("a", "b", "dep"), umg_edge("b", "a", "dep"))
  expect_error(umg_model(nodes, edges, list()), "W1")
})

test_that("W3: covariance edges require random vertices", {
  nodes <- list(umg_node("p", role = "par"),
                umg_node("y", observed = TRUE, dist = "free"))
  edges <- list(umg_edge("p", "y", "cov"))
  expect_error(umg_model(nodes, edges, list()), "W3")
})

test_that("W4: mixing edges require a latent categorical source", {
  nodes <- list(umg_node("z", observed = FALSE, support = "continuous",
                         dist = "N(0,1)"),
                umg_node("p", role = "par"))
  edges <- list(umg_edge("z", "p", "mix"))
  expect_error(umg_model(nodes, edges, list()), "W4")
})

test_that("W6: edges must reference declared vertices", {
  nodes <- list(umg_node("a", dist = "N(0,1)"))
  edges <- list(umg_edge("a", "ghost", "dep"))
  expect_error(umg_model(nodes, edges, list()), "undeclared")
})

test_that("W5: plate members must be declared", {
  nodes <- list(umg_node("a", dist = "N(0,1)"))
  plates <- list(umg_plate("p", c("a", "ghost"), "i"))
  expect_error(umg_model(nodes, list(), plates), "W5")
})

test_that("W2: an unannotated source random vertex warns", {
  nodes <- list(umg_node("a"), umg_node("y", observed = TRUE))
  edges <- list(umg_edge("a", "y", "dep"))
  expect_warning(umg_model(nodes, edges, list()), "W2")
})
