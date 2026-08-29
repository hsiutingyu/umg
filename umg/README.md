# umg: Unified Model Graphs for Statistical Models in Psychology

<!-- badges: start -->
<!-- badges: end -->

`umg` implements the **Unified Model Graph (UMG)** grammar: a single,
formally specified graphical notation for the statistical models
psychologists fit. A UMG types every vertex on three independent
dimensions (observability, support, inferential role), types every edge
by the kind of dependence it asserts (stochastic, symmetric,
deterministic, mixing), and uses plates to encode replication and
hierarchy. A well-formed diagram corresponds to a likelihood
factorisation, so the diagram is the model.

## Installation

```r
# from source
install.packages("path/to/umg", repos = NULL, type = "source")

# or, during development
# devtools::install_local("path/to/umg")
```

The package depends only on base R packages (`grid`, `grDevices`,
`stats`, `tools`, `utils`). Optional features are guarded behind
suggested packages: `ggplot2` (ggplot backend, EDA scaffolds),
`DiagrammeR` (Graphviz rendering), and `lavaan`, `lme4`, `mirt`,
`blavaan`, `brms`, `OpenMx`, `qgraph` (fitted-model converters).

## Three ways to build a diagram

```r
library(umg)

# 1. One-line motif builders
plot(umg_factor("F", paste0("y", 1:4)))      # reflective CFA
plot(umg_irt("graded"))                       # graded response IRT
plot(umg_riclpm(waves = 4))                   # RI-CLPM
plot(umg_mixture(umg_growth(4), c("I", "S"))) # growth mixture model

# 2. By hand, from typed primitives
m <- umg_model(
  nodes = list(
    umg_node("eta", "$\\eta_i$", observed = FALSE, dist = "N(0, psi)"),
    umg_node("y1", "$y_{1i}$", observed = TRUE),
    umg_node("y2", "$y_{2i}$", observed = TRUE)
  ),
  edges = list(
    umg_edge("eta", "y1", "dep", fixed = 1),
    umg_edge("eta", "y2", "dep", label = "$\\lambda_2$")
  ),
  plates = list(umg_plate("person", c("eta", "y1", "y2"), "i = 1, ..., N"))
)

# 3. From a fitted model object
# umg_from_lavaan(fit); umg_from_lmer(Reaction ~ Days + (Days | Subject))
# umg_from_mirt(fit); umg_from_brms(fit); umg_from_OpenMx(fit)
```

## Rendering

| Backend | Function | Output |
|---|---|---|
| Base `grid` | `plot(m)` / `umg_save(m, "f.pdf")` | PDF / PNG / SVG |
| `ggplot2` | `umg_ggplot(m)` / `autoplot(m)` | ggplot object |
| TikZ | `umg_to_tikz(m)` / `umg_save(m, "f.tex")` | LaTeX source |
| Graphviz | `umg_to_dot(m)` / `umg_render_dot(m)` | DOT / HTML widget |

Appearance is controlled by `umg_theme()` (`"journal"`, `"slide"`,
`"cb"` colour-blind-safe).

## Reading a diagram

```r
umg_validate(m)            # well-formedness rules W1-W6
umg_identify(m)            # scaling, counting rule, label switching, implied CIs
umg_dsep(m, "X", "Y", given = "M")   # d-separation reader
umg_eda_scaffold(m, data)  # exploratory displays implied by the duality
```

## Model families covered

Reflective and bifactor measurement, second-order and exploratory
(ESEM) factor models, formative and MIMIC measurement, general SEM,
the 1PL/2PL/3PL and graded/PCM/GPCM item response models (uni- and
multidimensional), diagnostic classification models, latent class and
profile models, growth and growth-mixture models, multilevel models,
the random-intercept cross-lagged panel model, Gaussian graphical
(network) models, and the Bayesian closure of any of them.

## Citation

Yu, H.-T. (2026). *Unified Model Graphs: A grammar for statistical
models in psychology.* (Manuscript.)

## License

MIT (c) Hsiu-Ting Yu.
