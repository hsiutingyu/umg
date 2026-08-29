# Tests for layout and the code-export backends (TikZ, DOT).

test_that("umg_layout attaches vertex coordinates and plate rects", {
  m <- umg_layout(umg_factor("F", paste0("y", 1:3)))
  expect_true(!is.null(m$layout))
  expect_true(all(c("name", "x", "y") %in% names(m$layout$vertices)))
  expect_equal(nrow(m$layout$vertices), length(m$nodes))
  expect_length(m$layout$plates, length(m$plates))
})

test_that("umg_layout honours orientation and coord overrides", {
  m <- umg_factor("F", paste0("y", 1:3))
  lr <- umg_layout(m, orientation = "LR")
  expect_true(!is.null(lr$layout))
  ov <- umg_layout(m, coords = data.frame(name = "F", x = 99, y = 99))
  expect_equal(ov$layout$vertices$x[ov$layout$vertices$name == "F"], 99)
})

test_that("umg_to_tikz emits a tikzpicture in the umg-style dialect", {
  code <- umg_to_tikz(umg_irt("2PL"))
  expect_type(code, "character")
  expect_true(any(grepl("\\\\begin\\{tikzpicture\\}", code)))
  expect_true(any(grepl("\\\\node", code)))
})

test_that("umg_to_dot emits Graphviz DOT", {
  code <- umg_to_dot(umg_factor("F", paste0("y", 1:3)))
  expect_type(code, "character")
  expect_true(grepl("digraph UMG", code[1]))
  expect_true(any(grepl("->", code)))
})

test_that("umg_save dispatches on extension", {
  tf <- tempfile(fileext = ".tex")
  umg_save(umg_factor("F", paste0("y", 1:3)), tf)
  expect_true(file.exists(tf))
  expect_true(any(grepl("tikzpicture", readLines(tf))))

  td <- tempfile(fileext = ".dot")
  umg_save(umg_irt("2PL"), td)
  expect_true(file.exists(td))

  expect_error(umg_save(umg_factor("F", paste0("y", 1:3)),
                        tempfile(fileext = ".bogus")))
})
