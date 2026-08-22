# Regression tests for the defects fixed in the 0.5.0 -> 0.6.0
# revision. Each test reproduces one of the numbered behaviours recorded
# in package_issues_V01.R (the reproduction script prepared with the
# companion manuscript), so that none of the fixes can regress silently.
# Issue numbers refer to that script.

# ----- Issue 1: meanstructure = TRUE counts the free means ------------

test_that("the counting rule reproduces lavaan's growth-model df with a
           mean structure (issue 1)", {
  # Demo.growth linear growth: 14 moments, 9 free, df = 5. The motif
  # carries no mean annotations, so the growth-model convention applies
  # (2 latent source means, indicators with zero intercepts).
  cnt <- umg_count_parameters(umg_growth(4), meanstructure = TRUE)
  expect_equal(cnt$data_information, 14)
  expect_equal(cnt$free$means, 2)
  expect_equal(cnt$free_total, 9)
  expect_equal(cnt$df, 5)
  # an all-observed regression: one intercept/mean per observed vertex
  cm <- umg_count_parameters(umg_mediation(), meanstructure = TRUE)
  expect_equal(cm$free$means, 3)
  expect_equal(cm$df, 0)
  # n_means overrides the automatic count; meanstructure = FALSE ignores it
  co <- umg_count_parameters(umg_growth(4), meanstructure = TRUE,
                             n_means = 6)
  expect_equal(co$free$means, 6)
  expect_equal(co$df, 1)
  expect_equal(umg_count_parameters(umg_growth(4), n_means = 6)$df, 3)
  expect_error(umg_count_parameters(umg_growth(4), meanstructure = TRUE,
                                    n_means = "two"))
  # umg_identify() passes n_means through
  expect_equal(umg_identify(umg_growth(4), meanstructure = TRUE,
                            n_means = 6)$count$df, 1)
})

test_that("the counting rule reads mean annotations from a lavaan fit
           (issues 1 and 14)", {
  skip_if_not_installed("lavaan")
  fit <- lavaan::growth("i =~ 1*t1+1*t2+1*t3+1*t4; s =~ 0*t1+1*t2+2*t3+3*t4",
                        data = lavaan::Demo.growth)
  m <- umg_from_lavaan(fit)
  cnt <- umg_count_parameters(m, meanstructure = TRUE)
  expect_equal(cnt$free$means, 2)
  expect_equal(cnt$df, as.numeric(lavaan::fitMeasures(fit, "df")))
  # a CFA with free observed intercepts and zero latent means: the mean
  # structure is saturated and the df is unchanged
  hs <- lavaan::cfa("visual =~ x1+x2+x3; textual =~ x4+x5+x6",
                    data = lavaan::HolzingerSwineford1939,
                    meanstructure = TRUE)
  mh <- umg_from_lavaan(hs)
  ch <- umg_count_parameters(mh, meanstructure = TRUE)
  expect_equal(ch$free$means, 6)
  expect_equal(ch$df, as.numeric(lavaan::fitMeasures(hs, "df")))
})

# ----- Issue 2: implied CIs listed once -------------------------------

test_that("umg_implied_ci lists each symmetric statement once (issue 2)", {
  ci <- umg_implied_ci(umg_mediation(confounder = TRUE),
                       observed_only = FALSE)
  expect_equal(nrow(ci), 1L)
  expect_identical(ci$x, "X")    # canonical: x precedes y in vertex order
  expect_identical(ci$y, "U")
  ci2 <- umg_implied_ci(umg_factor("F", paste0("y", 1:4)),
                        observed_only = FALSE)
  expect_equal(nrow(ci2), 6L)    # 0.5.0 returned 12 rows
  pairs <- paste(pmin(ci2$x, ci2$y), pmax(ci2$x, ci2$y))
  expect_false(anyDuplicated(pairs) > 0)
  expect_identical(rownames(ci2), as.character(seq_len(6L)))
  # print counts the de-duplicated set
  id <- umg_identify(umg_formative(paste0("x", 1:4),
                                   outcomes = c("y1", "y2")))
  expect_output(print(id), "independencies \\(observed\\): 6")
})

# ----- Issue 3: plate rules W5 ----------------------------------------

test_that("W5 refuses a child-plate member absent from the parent plate
           (issue 3a)", {
  nodes <- list(umg_node("y", observed = TRUE, dist = "N(mu, s)"),
                umg_node("b0", observed = FALSE),
                umg_node("g0", role = "par"))
  expect_error(
    umg_model(nodes, list(umg_edge("g0", "b0"), umg_edge("b0", "y")),
              list(umg_plate("occasion", c("y", "b0"), "t",
                             parent = "cluster"),
                   umg_plate("cluster", "b0", "i"))),
    "W5 violated: vertex 'y' is in plate 'occasion' but not in its parent plate 'cluster'",
    fixed = TRUE)
})

test_that("W5 refuses edges the index structure does not license
           (issues 3b and 3c)", {
  nodes <- list(umg_node("y", observed = TRUE, dist = "N(mu, s)"),
                umg_node("b0", observed = FALSE),
                umg_node("g0", role = "par"))
  # inner-plate y_t -> outer-plate b0_i
  expect_error(
    umg_model(nodes, list(umg_edge("g0", "b0"), umg_edge("y", "b0")),
              list(umg_plate("occasion", "y", "t", parent = "cluster"),
                   umg_plate("cluster", c("y", "b0"), "i"))),
    "edge y -> b0 is not licensed by the index structure", fixed = TRUE)
  # item-plate a_j -> person-plate theta_i in a 2PL diagram
  irt <- umg_irt("2PL")
  irt$edges <- c(irt$edges, list(umg_edge("a", "theta", "dep")))
  expect_error(umg_validate(irt),
               "edge a -> theta is not licensed by the index structure",
               fixed = TRUE)
  # the licensed direction (outer -> inner) is accepted
  expect_s3_class(
    umg_model(nodes, list(umg_edge("g0", "b0"), umg_edge("b0", "y")),
              list(umg_plate("occasion", "y", "t", parent = "cluster"),
                   umg_plate("cluster", c("y", "b0"), "i"))),
    "umg")
})

test_that("W5: cov edges need equal plate membership; det aggregates
           are exempt; mix edges are checked through their users", {
  a <- umg_node("a", observed = FALSE, dist = "N(0, 1)")
  b <- umg_node("b", observed = FALSE, dist = "N(0, 1)")
  expect_error(umg_model(list(a, b), list(umg_edge("a", "b", "cov")),
                         list(umg_plate("p", "a", "i"))),
               "cov edge a <-> b joins vertices with different plate membership",
               fixed = TRUE)
  # cluster mean of an occasion-level variable: refused unless marked
  # as an aggregate
  nodes <- list(umg_node("y", observed = TRUE, dist = "N(mu, s)"),
                umg_node("ybar", role = "det"))
  plates <- list(umg_plate("occasion", "y", "t", parent = "cluster"),
                 umg_plate("cluster", c("y", "ybar"), "i"))
  expect_error(umg_model(nodes, list(umg_edge("y", "ybar", "det")), plates),
               "not licensed")
  expect_s3_class(
    umg_model(nodes, list(umg_edge("y", "ybar", "det", aggregate = TRUE)),
              plates), "umg")
  expect_error(umg_edge("y", "ybar", "dep", aggregate = TRUE),
               "only meaningful for deterministic")
  expect_error(umg_edge("y", "ybar", "det", aggregate = NA), "TRUE or FALSE")
  # a person-level class selecting a parameter used by an item-level
  # vertex that is not person-indexed
  nodes <- list(umg_node("pi", role = "par"),
                umg_node("c", observed = FALSE, support = "categorical",
                         dist = "Categorical(pi)"),
                umg_node("mu", role = "par"),
                umg_node("u", observed = TRUE))
  edges <- list(umg_edge("pi", "c"), umg_edge("c", "mu", "mix"),
                umg_edge("mu", "u"))
  expect_error(
    umg_model(nodes, edges, list(umg_plate("person", "c", "i"),
                                 umg_plate("item", "u", "j"))),
    "mix edge from 'c' selects a parameter used by 'u', which is not replicated over the plates of 'c'",
    fixed = TRUE)
  expect_s3_class(
    umg_model(nodes, edges, list(umg_plate("person", c("c", "u"), "i"),
                                 umg_plate("item", "u", "j"))), "umg")
  # the mix target itself is exempt: a class inside the person plate
  # may select a parameter outside every plate (umg_mixture())
  expect_true(umg_validate(umg_mixture(umg_growth(4), c("I", "S"))))
})

test_that("every motif builder and converter validates under the W5
           index rules", {
  Q <- rbind(c(1, 1, 0, 0), c(0, 1, 1, 1))
  motifs <- list(
    umg_factor("F", paste0("y", 1:4)),
    umg_bifactor(paste0("y", 1:6), groups = list(g1 = paste0("y", 1:3),
                                                 g2 = paste0("y", 4:6))),
    umg_secondorder(list(F1 = paste0("y", 1:3), F2 = paste0("y", 4:6))),
    umg_esem(c("F1", "F2"), paste0("y", 1:6)),
    umg_formative(paste0("x", 1:4), outcomes = c("y1", "y2")),
    umg_mimic(c("z1", "z2"), paste0("y", 1:4)),
    umg_sem(list(F1 = paste0("y", 1:3), F2 = paste0("y", 4:6)),
            structural = list(c("F1", "F2"))),
    umg_irt("1PL"), umg_irt("2PL"), umg_irt("3PL"), umg_irt("graded"),
    umg_irt("PCM"), umg_irt("GPCM"), umg_irt("2PL", n_dim = 2),
    umg_dcm(Q), umg_lca(paste0("u", 1:4)), umg_growth(4),
    umg_mixture(umg_growth(4), c("I", "S")), umg_riclpm(waves = 4),
    umg_network(paste0("x", 1:4)), umg_mediation(),
    umg_mediation(confounder = TRUE), umg_from_mirt(2L, "graded"))
  for (m in motifs) expect_true(umg_validate(m))
  skip_if_not_installed("lme4")
  expect_true(umg_validate(
    umg_from_lmer(Reaction ~ Days + (Days | Subject), data = lme4::sleepstudy)))
  skip_if_not_installed("lavaan")
  expect_true(umg_validate(umg_from_lavaan(lavaan::cfa(
    "visual =~ x1+x2+x3; textual =~ x4+x5+x6; speed =~ x7+x8+x9",
    data = lavaan::HolzingerSwineford1939))))
})

# ----- Issues 4 and 5: scaling ----------------------------------------

test_that("a constant parent fixes the location, not the scale (issue 5)", {
  m5 <- umg_model(
    list(umg_node("F", observed = FALSE, dist = "N(0, psi)"),
         umg_node("one", role = "const"),
         umg_node("y1", observed = TRUE), umg_node("y2", observed = TRUE),
         umg_node("y3", observed = TRUE)),
    list(umg_edge("one", "F"), umg_edge("F", "y1"), umg_edge("F", "y2"),
         umg_edge("F", "y3")), list())
  sc <- umg_check_scaling(m5)
  expect_named(sc, c("vertex", "scaled", "via", "location_fixed"))
  expect_false(sc$scaled)
  expect_identical(sc$via, "none")
  expect_true(sc$location_fixed)
  expect_output(print(umg_identify(m5)), "UNSCALED: F")
  # the genuine marks are unaffected
  expect_identical(umg_check_scaling(umg_factor("F", paste0("y", 1:3)))$via,
                   "marker loading")
  expect_false(umg_check_scaling(umg_factor("F", paste0("y", 1:3)))$location_fixed)
  expect_identical(umg_check_scaling(umg_esem("F1", paste0("y", 1:4)))$via,
                   "fixed variance")
  expect_named(umg_check_scaling(umg_network(paste0("x", 1:3))),
               c("vertex", "scaled", "via", "location_fixed"))
})

test_that("umg_formative scales the composite by a marker weight
           (issue 4)", {
  m <- umg_formative(paste0("x", 1:4), outcomes = c("y1", "y2"))
  sc <- umg_check_scaling(m)
  expect_true(sc$scaled[sc$vertex == "C"])
  expect_identical(sc$via[sc$vertex == "C"], "marker weight")
  e <- as.data.frame(m)
  expect_equal(e$fixed[e$from == "x1" & e$to == "C"], 1)
  expect_true(all(is.na(e$fixed[e$from != "x1"])))
  cnt <- umg_count_parameters(m)
  expect_equal(cnt$free_total, 12)   # 3 weights + 2 loadings + 7 variances
  expect_equal(cnt$df, 9)
  # the unscaled drawing is still available and is flagged
  m0 <- umg_formative(paste0("x", 1:4), outcomes = c("y1", "y2"),
                      scaling = "none")
  expect_false(umg_check_scaling(m0)$scaled)
  expect_true(all(is.na(as.data.frame(m0)$fixed)))
})

# ----- Issues 7 and 8: DOT export -------------------------------------

test_that("umg_to_dot emits no style=curved and flags only crossed
           plates (issues 7 and 8)", {
  dot <- umg_to_dot(umg_sem(list(F1 = paste0("y", 1:3),
                                 F2 = paste0("y", 4:6)),
                            covariances = list(c("F1", "F2"))))
  expect_false(any(grepl("style=curved", dot, fixed = TRUE)))
  cov_line <- dot[grepl("\"F1\" -> \"F2\"", dot, fixed = TRUE)]
  expect_match(cov_line, "dir=both")
  expect_match(cov_line, "constraint=false")
  # nested plates: no crossed-plates note
  skip_if_not_installed("lme4")
  nested <- umg_to_dot(umg_from_lmer(Reaction ~ Days + (Days | Subject)))
  expect_false(any(grepl("crossed plates", nested, fixed = TRUE)))
  # crossed plates (persons x items): note present
  crossed <- umg_to_dot(umg_irt("2PL"))
  expect_true(any(grepl("crossed plates", crossed, fixed = TRUE)))
})

# ----- Issue 10: TikZ negative zero -----------------------------------

test_that("umg_to_tikz never prints a negative zero coordinate (issue 10)", {
  code <- umg_to_tikz(umg_factor("F", paste0("y", 1:3)))
  expect_equal(sum(grepl("-0[,)]", code)), 0L)
  m <- umg_layout(umg_factor("F", paste0("y", 1:2)),
                  coords = data.frame(name = "F", x = -0.001, y = -0.004))
  code2 <- umg_to_tikz(m)
  expect_true(any(grepl("(F) at (0,0)", code2, fixed = TRUE)))
})

# ----- Issue 14: mean structure through the converters ----------------

test_that("the mean structure of a growth model round-trips through
           cfa() (issue 14)", {
  skip_if_not_installed("lavaan")
  fit <- lavaan::growth("i =~ 1*t1+1*t2+1*t3+1*t4; s =~ 0*t1+1*t2+2*t3+3*t4",
                        data = lavaan::Demo.growth)
  m <- umg_from_lavaan(fit)
  ann <- vapply(m$nodes, function(v)
    if (is.null(v$annot)) "" else v$annot, character(1))
  expect_identical(unname(ann[c("i", "s")]), rep("mean = free", 2))
  expect_identical(unname(ann[paste0("t", 1:4)]), rep("mean = 0", 4))
  syn <- umg_to_lavaan(m)
  expect_match(syn, "i ~ 1")
  expect_match(syn, "t1 ~ 0\\*1")
  fm <- c("npar", "df", "chisq")
  refit_cfa <- lavaan::cfa(syn, data = lavaan::Demo.growth)
  refit_gr <- lavaan::growth(syn, data = lavaan::Demo.growth)
  expect_equal(as.numeric(lavaan::fitMeasures(refit_cfa, fm)),
               as.numeric(lavaan::fitMeasures(fit, fm)))
  expect_equal(as.numeric(lavaan::fitMeasures(refit_gr, fm)),
               as.numeric(lavaan::fitMeasures(fit, fm)))
  expect_equal(as.numeric(lavaan::fitMeasures(refit_cfa, "df")), 5)
  # a fit without a mean structure emits exactly the syntax it did before
  hs <- umg_from_lavaan(lavaan::cfa(
    "visual =~ x1+x2+x3; textual =~ x4+x5+x6",
    data = lavaan::HolzingerSwineford1939))
  expect_false(grepl("intercepts", umg_to_lavaan(hs), fixed = TRUE))
  expect_true(all(vapply(hs$nodes, function(v) is.null(v$annot), logical(1))))
  # a mean fixed at a sample value (fixed.x = TRUE) is recorded but not
  # emitted, so the refit reproduces the original
  set.seed(2)
  x <- stats::rnorm(200); f <- 0.5 * x + stats::rnorm(200)
  d <- data.frame(y1 = f + stats::rnorm(200, 0, 0.5),
                  y2 = 0.8 * f + stats::rnorm(200, 0, 0.5),
                  y3 = 1.2 * f + stats::rnorm(200, 0, 0.5), x = x)
  fx <- lavaan::sem("F =~ y1 + y2 + y3; F ~ x", data = d,
                    meanstructure = TRUE)
  mx <- umg_from_lavaan(fx)
  expect_identical(mx$nodes[["x"]]$annot, "mean = fixed")
  sx <- umg_to_lavaan(mx)
  expect_false(grepl("^x ~", sx) || grepl("\nx ~ ", sx))
  expect_equal(as.numeric(lavaan::fitMeasures(lavaan::sem(sx, data = d), fm)),
               as.numeric(lavaan::fitMeasures(fx, fm)))
  # syntax input with intercept rows
  ms <- umg_from_lavaan("F =~ y1 + y2 + y3\nF ~ 1\ny1 ~ 0*1")
  expect_identical(ms$nodes[["F"]]$annot, "mean = free")
  expect_identical(ms$nodes[["y1"]]$annot, "mean = 0")
})

test_that("mean annotations combine with existing annotations", {
  skip_if_not_installed("lavaan")
  fit <- lavaan::growth("i =~ 1*t1+1*t2+1*t3+1*t4; s =~ 0*t1+1*t2+2*t3+3*t4",
                        data = lavaan::Demo.growth)
  mb <- umg:::.umg_build_partable(lavaan::parameterTable(fit),
                                  bayesian = TRUE)
  expect_identical(mb$nodes[["i"]]$annot, "mean = free; prior")
  expect_identical(umg:::.umg_mean_annot(mb$nodes[["t1"]]), "0")
  expect_identical(umg:::.umg_annot_add("prior", "prior"), "prior")
  expect_null(umg:::.umg_mean_annot(umg_node("z", annot = "meaningful")))
})
