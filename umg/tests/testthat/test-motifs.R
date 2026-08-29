# Tests for the motif builders. Each must return a well-formed umg.

valid_umg <- function(m) {
  expect_s3_class(m, "umg")
  expect_true(umg_validate(m))
}

test_that("measurement motifs build and validate", {
  valid_umg(umg_factor("F", paste0("y", 1:4)))
  valid_umg(umg_bifactor(paste0("y", 1:6),
                         groups = list(g1 = paste0("y", 1:3),
                                       g2 = paste0("y", 4:6))))
  valid_umg(umg_secondorder(list(F1 = paste0("y", 1:3),
                                 F2 = paste0("y", 4:6))))
  valid_umg(umg_esem(c("F1", "F2"), paste0("y", 1:6)))
  valid_umg(umg_formative(paste0("x", 1:4), outcomes = c("y1", "y2")))
  valid_umg(umg_mimic(c("z1", "z2"), paste0("y", 1:4)))
})

test_that("general SEM builder honours measurement and structure", {
  m <- umg_sem(measurement = list(F1 = c("y1", "y2", "y3"),
                                  F2 = c("y4", "y5", "y6")),
               structural = list(c("F1", "F2")))
  valid_umg(m)
  expect_true("F1" %in% names(m$nodes))
  # structural edge present
  has_struct <- any(vapply(m$edges, function(e)
    e$from == "F1" && e$to == "F2" && e$kind == "dep", logical(1)))
  expect_true(has_struct)
})

test_that("growth, mediation, lca build and validate", {
  valid_umg(umg_growth(4))
  valid_umg(umg_mediation(confounder = TRUE, badge = "structural"))
  valid_umg(umg_lca(paste0("u", 1:4)))
  valid_umg(umg_lca(paste0("u", 1:4), categorical = FALSE))
})

test_that("IRT motif covers dichotomous, polytomous, and MIRT", {
  for (mod in c("1PL", "2PL", "3PL", "graded", "PCM", "GPCM"))
    valid_umg(umg_irt(mod))
  m2 <- umg_irt("2PL", n_dim = 2)
  valid_umg(m2)
  expect_true(all(c("theta1", "theta2") %in% names(m2$nodes)))
})

test_that("mixture wrapper composes with growth", {
  g <- umg_growth(4)
  gm <- umg_mixture(g, targets = c("I", "S"))
  valid_umg(gm)
  expect_true("c" %in% names(gm$nodes))
  has_mix <- any(vapply(gm$edges, function(e) e$kind == "mix", logical(1)))
  expect_true(has_mix)
})

test_that("network, riclpm, dcm build and validate", {
  valid_umg(umg_network(paste0("x", 1:4)))
  valid_umg(umg_riclpm(waves = 4))
  Q <- rbind(c(1, 1, 0), c(0, 1, 1))
  valid_umg(umg_dcm(Q))
})

test_that("badge is propagated by mediation", {
  m <- umg_mediation(badge = "structural")
  expect_identical(m$badge, "structural")
})
