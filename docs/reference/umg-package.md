# umg: Unified Model Graphs for Statistical Models in Psychology

The umg package implements the Unified Model Graph (UMG) grammar: a
single, formally specified graphical notation for the statistical models
psychologists fit. A UMG types every vertex on three independent
dimensions (observability, support, inferential role), types every edge
by the kind of dependence it asserts (stochastic, symmetric,
deterministic, mixing), and uses plates to encode replication and
hierarchy. A well-formed diagram corresponds to a likelihood
factorisation, so the diagram is the model.

## Building diagrams

Assemble diagrams by hand with
[`umg_node()`](https://hsiutingyu.github.io/umg/reference/umg_node.md),
[`umg_edge()`](https://hsiutingyu.github.io/umg/reference/umg_edge.md),
[`umg_plate()`](https://hsiutingyu.github.io/umg/reference/umg_plate.md),
and
[`umg_model()`](https://hsiutingyu.github.io/umg/reference/umg_model.md);
or use the one-line motif builders
([`umg_factor()`](https://hsiutingyu.github.io/umg/reference/umg_factor.md),
[`umg_bifactor()`](https://hsiutingyu.github.io/umg/reference/umg_bifactor.md),
[`umg_secondorder()`](https://hsiutingyu.github.io/umg/reference/umg_secondorder.md),
[`umg_esem()`](https://hsiutingyu.github.io/umg/reference/umg_esem.md),
[`umg_formative()`](https://hsiutingyu.github.io/umg/reference/umg_formative.md),
[`umg_mimic()`](https://hsiutingyu.github.io/umg/reference/umg_mimic.md),
[`umg_sem()`](https://hsiutingyu.github.io/umg/reference/umg_sem.md),
[`umg_growth()`](https://hsiutingyu.github.io/umg/reference/umg_growth.md),
[`umg_mediation()`](https://hsiutingyu.github.io/umg/reference/umg_mediation.md),
[`umg_lca()`](https://hsiutingyu.github.io/umg/reference/umg_lca.md),
[`umg_irt()`](https://hsiutingyu.github.io/umg/reference/umg_irt.md),
[`umg_dcm()`](https://hsiutingyu.github.io/umg/reference/umg_dcm.md),
[`umg_mixture()`](https://hsiutingyu.github.io/umg/reference/umg_mixture.md),
[`umg_network()`](https://hsiutingyu.github.io/umg/reference/umg_network.md),
[`umg_riclpm()`](https://hsiutingyu.github.io/umg/reference/umg_riclpm.md));
or translate a fitted model with
[`umg_from_lavaan()`](https://hsiutingyu.github.io/umg/reference/umg_from_lavaan.md),
[`umg_from_lmer()`](https://hsiutingyu.github.io/umg/reference/umg_from_lmer.md),
[`umg_from_mirt()`](https://hsiutingyu.github.io/umg/reference/umg_from_mirt.md),
[`umg_from_blavaan()`](https://hsiutingyu.github.io/umg/reference/umg_from_blavaan.md),
[`umg_from_brms()`](https://hsiutingyu.github.io/umg/reference/umg_from_brms.md),
[`umg_from_OpenMx()`](https://hsiutingyu.github.io/umg/reference/umg_from_OpenMx.md),
or
[`umg_from_qgraph()`](https://hsiutingyu.github.io/umg/reference/umg_from_qgraph.md).

## Rendering

Render with base graphics
([`plot.umg()`](https://hsiutingyu.github.io/umg/reference/plot.umg.md)),
ggplot2
([`umg_ggplot()`](https://hsiutingyu.github.io/umg/reference/umg_ggplot.md)),
TikZ
([`umg_to_tikz()`](https://hsiutingyu.github.io/umg/reference/umg_to_tikz.md)),
or Graphviz DOT
([`umg_to_dot()`](https://hsiutingyu.github.io/umg/reference/umg_to_dot.md),
[`umg_render_dot()`](https://hsiutingyu.github.io/umg/reference/umg_render_dot.md)).
[`umg_save()`](https://hsiutingyu.github.io/umg/reference/umg_save.md)
dispatches on the file extension. Appearance is controlled by
[`umg_theme()`](https://hsiutingyu.github.io/umg/reference/umg_theme.md).

## Reasoning about a diagram

[`umg_validate()`](https://hsiutingyu.github.io/umg/reference/umg_validate.md)
enforces the well-formedness rules;
[`umg_identify()`](https://hsiutingyu.github.io/umg/reference/umg_identify.md)
(with
[`umg_check_scaling()`](https://hsiutingyu.github.io/umg/reference/umg_check_scaling.md),
[`umg_count_parameters()`](https://hsiutingyu.github.io/umg/reference/umg_count_parameters.md),
[`umg_labelswitching()`](https://hsiutingyu.github.io/umg/reference/umg_labelswitching.md),
[`umg_dsep()`](https://hsiutingyu.github.io/umg/reference/umg_dsep.md),
and
[`umg_implied_ci()`](https://hsiutingyu.github.io/umg/reference/umg_implied_ci.md))
reads identification-relevant information off the page.
[`umg_eda_scaffold()`](https://hsiutingyu.github.io/umg/reference/umg_eda_scaffold.md)
and
[`umg_caterpillar()`](https://hsiutingyu.github.io/umg/reference/umg_caterpillar.md)
generate the exploratory displays implied by the model-data duality.

## See also

Useful links:

- <https://github.com/hsiutingyu/umg>

- Report bugs at <https://github.com/hsiutingyu/umg/issues>

## Author

**Maintainer**: Hsiu-Ting Yu <hsiutingyu@gmail.com>
([ORCID](https://orcid.org/0000-0002-3668-8033))

Authors:

- Hsiu-Ting Yu <hsiutingyu@gmail.com>
  ([ORCID](https://orcid.org/0000-0002-3668-8033))
