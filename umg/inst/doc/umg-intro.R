## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(collapse = TRUE, comment = "#>",
                      fig.width = 7, fig.height = 5)
library(umg)

## ----cfa-by-hand--------------------------------------------------------------
m <- umg_model(
  nodes = list(
    umg_node("eta", "$\\eta_i$", observed = FALSE, dist = "N(0, psi)"),
    umg_node("y1", "$y_{1i}$", observed = TRUE),
    umg_node("y2", "$y_{2i}$", observed = TRUE),
    umg_node("y3", "$y_{3i}$", observed = TRUE)
  ),
  edges = list(
    umg_edge("eta", "y1", "dep", fixed = 1),
    umg_edge("eta", "y2", "dep", label = "$\\lambda_2$"),
    umg_edge("eta", "y3", "dep", label = "$\\lambda_3$")
  ),
  plates = list(
    umg_plate("person", c("eta", "y1", "y2", "y3"), "i = 1, ..., N")
  )
)
m
plot(m)

## ----lavaan, eval = requireNamespace("lavaan", quietly = TRUE)----------------
model_syntax <- '
  visual  =~ x1 + x2 + x3
  textual =~ x4 + x5 + x6
  speed   =~ x7 + x8 + x9
'
g <- umg_from_lavaan(model_syntax)
plot(g)

## ----lmer, eval = requireNamespace("lme4", quietly = TRUE)--------------------
g2 <- umg_from_lmer(Reaction ~ Days + (Days | Subject))
plot(g2)

## ----tikz---------------------------------------------------------------------
cat(head(umg_to_tikz(m), 12), sep = "\n")

## ----duality, eval = requireNamespace("lme4", quietly = TRUE) && requireNamespace("ggplot2", quietly = TRUE)----
data(sleepstudy, package = "lme4")
plots <- umg_eda_scaffold(g2, sleepstudy, id = "Subject", time = "Days")
names(plots)
plots$spaghetti

## ----inspect------------------------------------------------------------------
m_sem <- umg_sem(
  measurement = list(F1 = paste0("y", 1:3), F2 = paste0("y", 4:6)),
  structural  = list(c("F1", "F2"))
)
as.data.frame(m_sem)                    # edges
as.data.frame(m_sem, what = "vertices") # vertices
summary(m_sem)

## ----to-lavaan----------------------------------------------------------------
cat(umg_to_lavaan(m_sem))

## ----roundtrip, eval = requireNamespace("lavaan", quietly = TRUE)-------------
syntax  <- "visual =~ x1 + x2 + x3\ntextual =~ x4 + x5 + x6"
g       <- umg_from_lavaan(syntax)   # syntax  -> diagram
back    <- umg_to_lavaan(g)          # diagram -> syntax
cat(back)

