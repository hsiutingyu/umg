# ============================================================
# Title:  Package-level documentation and global declarations
# File:   umg-package.R (package umg)
# Author: H.-T. Yu
# Date:   2026-06-19
# ============================================================

#' umg: Unified Model Graphs for Statistical Models in Psychology
#'
#' The umg package implements the Unified Model Graph (UMG) grammar: a
#' single, formally specified graphical notation for the statistical
#' models psychologists fit. A UMG types every vertex on three
#' independent dimensions (observability, support, inferential role),
#' types every edge by the kind of dependence it asserts (stochastic,
#' symmetric, deterministic, mixing), and uses plates to encode
#' replication and hierarchy. A well-formed diagram corresponds to a
#' likelihood factorisation, so the diagram is the model.
#'
#' @section Building diagrams:
#' Assemble diagrams by hand with [umg_node()], [umg_edge()],
#' [umg_plate()], and [umg_model()]; or use the one-line motif
#' builders ([umg_factor()], [umg_bifactor()], [umg_secondorder()],
#' [umg_esem()], [umg_formative()], [umg_mimic()], [umg_sem()],
#' [umg_growth()], [umg_mediation()], [umg_lca()], [umg_irt()],
#' [umg_dcm()], [umg_mixture()], [umg_network()], [umg_riclpm()]); or
#' translate a fitted model with [umg_from_lavaan()], [umg_from_lmer()],
#' [umg_from_mirt()], [umg_from_blavaan()], [umg_from_brms()],
#' [umg_from_OpenMx()], or [umg_from_qgraph()].
#'
#' @section Rendering:
#' Render with base graphics ([plot.umg()]), \pkg{ggplot2}
#' ([umg_ggplot()]), TikZ ([umg_to_tikz()]), or Graphviz DOT
#' ([umg_to_dot()], [umg_render_dot()]). [umg_save()] dispatches on the
#' file extension. Appearance is controlled by [umg_theme()].
#'
#' @section Reasoning about a diagram:
#' [umg_validate()] enforces the well-formedness rules; [umg_identify()]
#' (with [umg_check_scaling()], [umg_count_parameters()],
#' [umg_labelswitching()], [umg_dsep()], and [umg_implied_ci()]) reads
#' identification-relevant information off the page. [umg_eda_scaffold()]
#' and [umg_caterpillar()] generate the exploratory displays implied by
#' the model-data duality.
#'
#' @keywords internal
#' @importFrom utils globalVariables
"_PACKAGE"

# Non-standard evaluation in the ggplot2 backends references `.data`;
# declare it to silence the R CMD check "no visible binding" note
# without taking a hard dependency on rlang.
globalVariables(c(".data", "density"))
