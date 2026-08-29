# ============================================================
# Title:  Export UMG diagrams to image and code files
# File:   save.R (package umg)
# Author: H.-T. Yu
# Date:   2026-06-18
# ============================================================

#' Save a UMG diagram to a file
#'
#' Renders a UMG to a graphics file (PDF, PNG, or SVG), or writes code
#' for one of the export backends. The output format is taken from the
#' file extension: `.pdf`/`.png`/`.svg` produce graphics,
#' `.tex`/`.tikz` produce TikZ source, and `.dot`/`.gv` produce
#' Graphviz DOT source. Graphics may be produced with either the base
#' `grid` renderer (default) or the \pkg{ggplot2} backend. Graphics
#' dimensions are in inches.
#'
#' @param model An object of class `umg`.
#' @param file Output path; the extension (`.pdf`, `.png`, `.svg`,
#'   `.tex`/`.tikz`, `.dot`/`.gv`) selects the format.
#' @param width,height Dimensions in inches for graphics devices.
#' @param res Resolution in dpi for PNG output.
#' @param theme A `umg_theme` for graphics output (see [umg_theme()]).
#' @param backend Graphics backend for raster/vector output:
#'   `"grid"` (default) or `"ggplot"`.
#' @param ... Passed to [plot.umg()] / [umg_ggplot()] (graphics),
#'   [umg_to_tikz()] (TikZ), or [umg_to_dot()] (DOT).
#' @return The path `file`, invisibly.
#' @examples
#' umg_save(umg_factor("F", paste0("y", 1:4)),
#'          tempfile(fileext = ".pdf"))
#' umg_save(umg_irt("2PL"), tempfile(fileext = ".tex"))
#' umg_save(umg_irt("2PL"), tempfile(fileext = ".dot"))
#' @export
umg_save <- function(model, file, width = 6, height = 4.5, res = 300,
                     theme = umg_theme(), backend = c("grid", "ggplot"),
                     ...) {
  stopifnot(inherits(model, "umg"), is.character(file), length(file) == 1L)
  backend <- match.arg(backend)
  ext <- tolower(tools::file_ext(file))
  if (ext %in% c("tex", "tikz")) {
    umg_to_tikz(model, file = file, ...)
    return(invisible(file))
  }
  if (ext %in% c("dot", "gv")) {
    umg_to_dot(model, file = file, theme = theme, ...)
    return(invisible(file))
  }
  if (!ext %in% c("pdf", "png", "svg"))
    stop("Unsupported extension '", ext,
         "'. Use pdf, png, svg, tex, tikz, dot, or gv.")
  if (backend == "ggplot") {
    .umg_require("ggplot2", "umg_save(backend = \"ggplot\")")
    g <- umg_ggplot(model, theme = theme, ...)
    if (ext == "svg") {
      # route svg through grDevices so that the svglite package (which
      # ggsave would dispatch to) is not required
      grDevices::svg(file, width = width, height = height)
      on.exit(grDevices::dev.off(), add = TRUE)
      print(g)
    } else {
      ggplot2::ggsave(file, plot = g, width = width, height = height,
                      dpi = res)
    }
    return(invisible(file))
  }
  switch(ext,
    pdf = grDevices::pdf(file, width = width, height = height),
    png = grDevices::png(file, width = width, height = height,
                         units = "in", res = res),
    svg = grDevices::svg(file, width = width, height = height))
  on.exit(grDevices::dev.off(), add = TRUE)
  plot(model, theme = theme, ...)
  invisible(file)
}
