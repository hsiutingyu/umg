## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(collapse = TRUE, comment = "#>")
library(umg)

## ----scaling------------------------------------------------------------------
umg_check_scaling(umg_factor("F", paste0("y", 1:4)))   # marker loading
umg_check_scaling(umg_esem("F1", paste0("y", 1:4)))    # fixed variance

## ----counting-----------------------------------------------------------------
umg_count_parameters(umg_factor("F", paste0("y", 1:6)))

## ----labelswitch--------------------------------------------------------------
umg_labelswitching(umg_mixture(umg_growth(4), c("I", "S")))

## ----dsep---------------------------------------------------------------------
med <- umg_mediation(direct = FALSE)
umg_dsep(med, "X", "Y")               # FALSE: connected through M
umg_dsep(med, "X", "Y", given = "M")  # TRUE: blocked by the mediator

## ----impliedci----------------------------------------------------------------
umg_implied_ci(umg_mediation(direct = FALSE))

## ----identify-----------------------------------------------------------------
umg_identify(umg_factor("F", paste0("y", 1:6)))

