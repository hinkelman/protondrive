test_that("pd_mkdir() creates a folder in a parent", {
  log <- local_fake_cli(
    "filesystem info" = cli_fail("Node not found: new"),
    "filesystem create-folder" = function(pos, ...) fake_node(pos[[2]], 5, type = "folder")
  )
  x <- pd_mkdir("new", path = "data")
  create <- log$calls[[2]]
  expect_equal(positional(create), c("/my-files/data", "new"))
  expect_equal(x$path, "/my-files/data/new")
  expect_equal(x$name, "new")
})

test_that("pd_mkdir() splits a path given as the name", {
  log <- local_fake_cli(
    "filesystem info" = cli_fail("Node not found"),
    "filesystem create-folder" = function(pos, ...) fake_node(pos[[2]], 5, type = "folder")
  )
  x <- pd_mkdir("a/b/c")
  expect_equal(positional(log$calls[[2]]), c("/my-files/a/b", "c"))
  expect_equal(x$path, "/my-files/a/b/c")
})

test_that("pd_mkdir() refuses to clobber unless overwrite = TRUE", {
  withr::local_options(protondrive_quiet = FALSE)
  log <- local_fake_cli(
    "filesystem info" = fake_node("new", 4, type = "folder"),
    "filesystem trash" = node_results(fake_uid(4)),
    "filesystem create-folder" = fake_node("new", 5, type = "folder")
  )
  expect_error(pd_mkdir("new"), class = "protondrive_conflict")
  expect_length(log$calls, 1)

  expect_message(x <- pd_mkdir("new", overwrite = TRUE), "Moved existing")
  commands <- vapply(log$calls, function(a) paste(a[1:2], collapse = " "), "")
  expect_equal(commands[-1], c("filesystem info", "filesystem trash", "filesystem create-folder"))
  expect_equal(vctrs::vec_data(x$id), fake_uid(5))
})
