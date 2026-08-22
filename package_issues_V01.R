# ============================================================
# Title:  Minimal reproductions of umg 0.5.0 behaviours flagged during the demonstrations
# File:   package_issues_V01.R
# Author: HTYu
# Date:   2026-08-22
# ============================================================
# Each numbered block reproduces one behaviour that looked like a bug, a
# documentation/code mismatch, a misleading message, or a rendering
# defect, and prints the evidence. Nothing here edits the package.
# Run: Rscript R/package_issues_V01.R
# Output: output/package_issues_V01.txt (+ output/issue_*.png)

#----- Packages & Setup -----------------------------------------------------
library(umg); library(lavaan)
script_dir <- local({
  a <- commandArgs(trailingOnly = FALSE)
  f <- sub("^--file=", "", a[grepl("^--file=", a)])
  if (length(f)) dirname(normalizePath(f[1])) else getwd()
})
out_dir <- normalizePath(file.path(script_dir, "..", "output"), mustWork = FALSE)
con <- file(file.path(out_dir, "package_issues_V01.txt"), open = "wt")
sink(con, split = TRUE)
cat("package_issues_V01.R  --  umg", as.character(packageVersion("umg")), "--", format(Sys.time()), "\n")
cap <- function(expr) withCallingHandlers(tryCatch(expr, error = function(e) { cat("  ERROR:", conditionMessage(e), "\n"); NULL }),
  warning = function(w) { cat("  WARNING:", conditionMessage(w), "\n"); invokeRestart("muffleWarning") },
  message = function(m) { cat("  MESSAGE:", conditionMessage(m)); invokeRestart("muffleMessage") })

#----- Issue 1: meanstructure = TRUE counts one free mean per random vertex ---
cat("\n[1] umg_count_parameters(meanstructure = TRUE): documentation says 'a mean parameter per\n",
    "    source vertex'; the code counts one per random vertex (all rv), so df is wrong.\n", sep = "")
fit_gr <- growth('i =~ 1*t1+1*t2+1*t3+1*t4; s =~ 0*t1+1*t2+2*t3+3*t4', data = Demo.growth)
m_gr <- umg_from_lavaan(fit_gr)
cnt <- umg_count_parameters(m_gr, meanstructure = TRUE)
cat(sprintf("  moments = %d, free means counted = %d (source vertices: 2), total free = %d, df = %d; lavaan: npar = %d, df = %d\n",
            cnt$data_information, cnt$free$means, cnt$free_total, cnt$df, fitMeasures(fit_gr, "npar"), fitMeasures(fit_gr, "df")))
cat("  source code: free_mean <- sum(vapply(nodes, function(v) v$role == 'rv', logical(1)))  [all rv, not sources]\n")

#----- Issue 2: umg_implied_ci lists each symmetric statement twice ----------
cat("\n[2] umg_implied_ci() returns both (x, y | Z) and (y, x | Z) for the same independence:\n")
ci <- umg_implied_ci(umg_mediation(confounder = TRUE), observed_only = FALSE); print(ci)
ci2 <- umg_implied_ci(umg_factor("F", paste0("y", 1:4)), observed_only = FALSE)
cat("  one-factor, 4 indicators: rows =", nrow(ci2), "; unordered pairs =", length(unique(paste(pmin(ci2$x, ci2$y), pmax(ci2$x, ci2$y)))), "\n")
cat("  (print.umg_identification reports nrow(implied_ci) as the number of implied CIs.)\n")

#----- Issue 3: plate rules -------------------------------------------------
cat("\n[3] umg_validate() W5 accepts (a) a child-plate member absent from the parent plate and\n",
    "    (b) edges crossing plate boundaries that no index licenses (no index-licensing rule):\n", sep = "")
nodes <- list(umg_node("y", observed = TRUE, dist = "N(mu, s)"), umg_node("b0", observed = FALSE), umg_node("g0", role = "par"))
r <- cap(umg_model(nodes, list(umg_edge("g0", "b0"), umg_edge("b0", "y")),
                   list(umg_plate("occasion", c("y", "b0"), "t", parent = "cluster"), umg_plate("cluster", "b0", "i"))))
cat("  (a) child member 'y' not in parent plate ->", if (inherits(r, "umg")) "ACCEPTED" else "refused", "\n")
r <- cap(umg_model(nodes, list(umg_edge("g0", "b0"), umg_edge("y", "b0")),
                   list(umg_plate("occasion", "y", "t", parent = "cluster"), umg_plate("cluster", c("y", "b0"), "i"))))
cat("  (b) inner-plate y_t -> outer-plate b0_i ->", if (inherits(r, "umg")) "ACCEPTED" else "refused", "\n")
irt <- umg_irt("2PL"); irt$edges <- c(irt$edges, list(umg_edge("a", "theta", "dep")))
cat("  (c) item-plate a_j -> person-plate theta_i in umg_irt('2PL') -> umg_validate:", cap(umg_validate(irt)), "\n")

#----- Issue 4: umg_formative() is unscaled by its own check -----------------
cat("\n[4] umg_formative() output is flagged by umg_check_scaling():\n")
print(umg_check_scaling(umg_formative(paste0("x", 1:4), outcomes = c("y1", "y2"))))

#----- Issue 5: any 'const' parent counts as a scaling mark ------------------
cat("\n[5] umg_check_scaling() treats any constant parent as fixing the scale (via = 'constant parent'),\n",
    "    although a constant parent fixes a location, not a variance:\n", sep = "")
m5 <- umg_model(list(umg_node("F", observed = FALSE, dist = "N(0, psi)"), umg_node("one", role = "const"),
                     umg_node("y1", observed = TRUE), umg_node("y2", observed = TRUE), umg_node("y3", observed = TRUE)),
                list(umg_edge("one", "F"), umg_edge("F", "y1"), umg_edge("F", "y2"), umg_edge("F", "y3")), list())
print(umg_check_scaling(m5))

#----- Issue 6: dist / annot never rendered ---------------------------------
cat("\n[6] ?umg_node says 'Annotations are available to renderers and exporters', but no backend\n",
    "    draws dist or annot. grep over the installed 0.5.0 sources (plot/ggplot/tikz/dot):\n", sep = "")
src <- system.file("R", package = "umg")   # byte-compiled; use the namespace instead
for (f in c("plot.umg", "umg_ggplot", "umg_to_tikz", "umg_to_dot")) {
  body_txt <- paste(deparse(get(f, envir = asNamespace("umg"))), collapse = "\n")
  cat(sprintf("  %-12s mentions 'dist': %-5s mentions 'annot': %s\n", f, grepl("\\$dist", body_txt), grepl("\\$annot", body_txt)))
}
m6 <- umg_node("a", "$a_j$", observed = FALSE, dist = "LogNormal(0, 1)", annot = "prior")
cat("  e.g. node a: dist =", m6$dist, "| annot =", m6$annot, "-> neither appears in umg_to_tikz()/umg_to_dot() output:\n")
m6m <- umg_model(list(m6, umg_node("u", observed = TRUE, support = "categorical", dist = "Bernoulli(p)")), list(umg_edge("a", "u")), list())
cat("  tikz contains 'LogNormal':", any(grepl("LogNormal", umg_to_tikz(m6m))), "| dot contains 'LogNormal':", any(grepl("LogNormal", umg_to_dot(m6m))), "\n")

#----- Issue 7: DOT 'style=curved' is not a Graphviz edge style ---------------
cat("\n[7] umg_to_dot() writes style=curved on cov edges; Graphviz rejects it:\n")
f7 <- file.path(out_dir, "issue7_hs.dot")
umg_to_dot(umg_from_lavaan(cfa('visual =~ x1+x2+x3; textual =~ x4+x5+x6', data = HolzingerSwineford1939)), file = f7)
if (nzchar(Sys.which("dot"))) cat("  dot -Tpng:", paste(system2("dot", c("-Tpng", shQuote(f7), "-o", "/dev/null"), stdout = TRUE, stderr = TRUE), collapse = " | "), "\n")

#----- Issue 8: 'crossed plates' note for nested plates ----------------------
cat("\n[8] umg_to_dot() appends '// note: crossed plates rendered by smallest-enclosing assignment'\n",
    "    for NESTED plates too (a member of a child plate is also a member of its parent):\n", sep = "")
library(lme4)
d8 <- umg_to_dot(umg_from_lmer(Reaction ~ Days + (Days | Subject), data = sleepstudy))
cat("  note present for the nested sleepstudy diagram:", any(grepl("crossed plates", d8)), "\n")

#----- Issue 9: rendering defects -------------------------------------------
cat("\n[9] Rendering: (a) arrowheads into square (categorical) vertices are hidden under the glyph on\n",
    "    diagonal approaches (edge shrink uses the circle radius); (b) nested inner-plate index label\n",
    "    collides with a vertex; (c) fixed-loading labels overlap in umg_growth(); (d) ggplot backend:\n",
    "    long factor labels overflow the node glyph and cov curves cross intermediate nodes.\n", sep = "")
png(file.path(out_dir, "issue9a_irt_arrowheads.png"), 1200, 900, res = 150); plot(umg_irt("2PL")); dev.off()
png(file.path(out_dir, "issue9b_nested_label.png"), 1200, 900, res = 150); plot(umg_from_lmer(Reaction ~ Days + (Days | Subject), data = sleepstudy)); dev.off()
png(file.path(out_dir, "issue9c_growth_labels.png"), 1200, 900, res = 150); plot(umg_growth(4)); dev.off()
cat("  see output/issue9a_irt_arrowheads.png, issue9b_nested_label.png, issue9c_growth_labels.png,\n",
    "  and output/backend_ggplot_hs_cfa.png\n", sep = "")

#----- Issue 10: TikZ '-0' coordinates (cosmetic) ----------------------------
cat("\n[10] umg_to_tikz() prints negative zero coordinates ('-0'):\n")
cat("  lines with '-0)' or '-0,':", sum(grepl("-0[,)]", umg_to_tikz(umg_factor("F", paste0("y", 1:3))))), "\n")

#----- Issue 11: exogenous causes drawn without covariance (MIMIC/formative) ---
cat("\n[11] umg_mimic()/umg_formative() draw no covariance among the observed causes, so the diagram\n",
    "    literally asserts their independence; the counting rule then differs from the fitted MIMIC:\n", sep = "")
mm <- umg_mimic(c("z1", "z2"), paste0("y", 1:4)); cm <- umg_count_parameters(mm)
cat(sprintf("  umg_mimic: %d moments, %d free, df = %d; implied observed CIs: %s\n", cm$data_information, cm$free_total, cm$df,
            paste(apply(umg_implied_ci(mm), 1, paste, collapse = "_|_"), collapse = "; ")))
set.seed(1); dd <- as.data.frame(matrix(rnorm(600), 100, 6, dimnames = list(NULL, c("z1", "z2", paste0("y", 1:4)))))
fitm <- sem('F =~ y1 + y2 + y3 + y4; F ~ z1 + z2', data = dd)
cat(sprintf("  lavaan MIMIC (fixed.x = TRUE default): npar = %d, df = %d\n", fitMeasures(fitm, "npar"), fitMeasures(fitm, "df")))

#----- Issue 12: ESEM counting rule ignores rotational constraints -----------
cat("\n[12] umg_esem(): the t-rule count ignores the m(m-1) rotational constraints of EFA:\n")
ce <- umg_count_parameters(umg_esem(c("F1", "F2"), paste0("y", 1:6)))
cat(sprintf("  2 factors, 6 indicators: %d moments, %d free, df = %d; EFA df = ((6-2)^2 - (6+2))/2 = 4\n", ce$data_information, ce$free_total, ce$df))

#----- Issue 13: score_<latent> proxy for a slope factor ---------------------
cat("\n[13] umg_eda_scaffold(): the 'score_S' display for a growth slope uses the row mean of the\n",
    "    repeated measures (same proxy as for the intercept), which is not a slope proxy:\n", sep = "")
gm <- as.data.frame(matrix(rnorm(400), 100, 4, dimnames = list(NULL, paste0("y", 1:4))))
sc <- cap(umg_eda_scaffold(umg_growth(4), gm))
cat("  displays:", paste(names(sc), collapse = ", "), "| x label of score_S:", sc$score_S$labels$x, "\n")

#----- Issue 14: mean structure not carried by the round trip ----------------
cat("\n[14] umg_from_lavaan() ignores '~1' rows and umg_to_lavaan() emits no intercepts; a growth\n",
    "    model round-trips only because growth() re-adds the mean structure (cfa() refit differs):\n", sep = "")
syn <- umg_to_lavaan(m_gr)
cat(sprintf("  growth() refit df = %d; cfa() refit df = %d; original df = %d\n",
            fitMeasures(growth(syn, data = Demo.growth), "df"), fitMeasures(cfa(syn, data = Demo.growth), "df"), fitMeasures(fit_gr, "df")))

cat("\nDone:", format(Sys.time()), "\n")
sink(); close(con)
