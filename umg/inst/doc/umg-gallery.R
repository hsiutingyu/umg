## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(collapse = TRUE, comment = "#>",
                      fig.width = 6.5, fig.height = 4.5, dpi = 96)
library(umg)

## ----cfa----------------------------------------------------------------------
plot(umg_factor("F", paste0("y", 1:5)))

## ----bifactor-----------------------------------------------------------------
plot(umg_bifactor(paste0("y", 1:6),
                  groups = list(g1 = paste0("y", 1:3),
                                g2 = paste0("y", 4:6))))

## ----secondorder--------------------------------------------------------------
plot(umg_secondorder(list(F1 = paste0("y", 1:3),
                          F2 = paste0("y", 4:6),
                          F3 = paste0("y", 7:9))))

## ----esem---------------------------------------------------------------------
plot(umg_esem(c("F1", "F2"), paste0("y", 1:6)))

## ----formative----------------------------------------------------------------
plot(umg_formative(paste0("x", 1:4), outcomes = c("y1", "y2")))
plot(umg_mimic(c("age", "sex"), paste0("y", 1:4)))

## ----irt----------------------------------------------------------------------
plot(umg_irt("2PL"))
plot(umg_irt("graded"))     # graded response model
plot(umg_irt("2PL", n_dim = 2))  # multidimensional IRT

## ----dcm----------------------------------------------------------------------
Q <- rbind(c(1, 1, 0, 0, 1, 0),
           c(0, 1, 1, 0, 0, 1),
           c(0, 0, 1, 1, 1, 1))
plot(umg_dcm(Q))

## ----growth-------------------------------------------------------------------
plot(umg_growth(4))
plot(umg_riclpm(waves = 4))   # random-intercept cross-lagged panel

## ----gmm----------------------------------------------------------------------
plot(umg_mixture(umg_growth(4), targets = c("I", "S")))
plot(umg_lca(paste0("u", 1:5)))   # latent class analysis

## ----network------------------------------------------------------------------
plot(umg_network(paste0("x", 1:5)))

## ----sem----------------------------------------------------------------------
m <- umg_sem(
  measurement = list(F1 = paste0("y", 1:3),
                     F2 = paste0("y", 4:6),
                     F3 = paste0("y", 7:9)),
  structural  = list(c("F1", "F3"), c("F2", "F3"))
)
plot(m)

## ----badge--------------------------------------------------------------------
plot(umg_mediation(confounder = TRUE, badge = "structural"))

