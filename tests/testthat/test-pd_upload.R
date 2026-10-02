test_that("pd_upload() uploads into a folder and returns the new file", {
  local <- withr::local_tempfile(fileext = ".csv")
  writeLines("a,b", local)
  log <- local_fake_cli(
    "filesystem upload" = list(transferredItems = 1, transferredBytes = 4,
                               skippedItems = 0, failedItems = 0, failures = list()),
    "filesystem info" = fake_node(basename(local), 7)
  )
  x <- pd_upload(local, path = "data")
  upload <- log$calls[[1]]
  expect_equal(positional(upload), c(normalizePath(local), "/my-files/data"))
  expect_false("--file-conflict-strategy" %in% upload)
  expect_false("--skip-thumbnails" %in% upload)
  expect_equal(positional(log$calls[[2]]), paste0("/my-files/data/", basename(local)))
  expect_equal(x$path, paste0("/my-files/data/", basename(local)))
})

test_that("pd_upload() stages a renamed copy", {
  local <- withr::local_tempfile(fileext = ".csv")
  writeLines("a,b", local)
  seen <- NULL
  local_fake_cli(
    "filesystem upload" = function(pos, ...) {
      seen <<- pos[[1]]
      expect_equal(readLines(pos[[1]]), "a,b")
      list(transferredItems = 1, transferredBytes = 4, skippedItems = 0)
    },
    "filesystem info" = fake_node("renamed.csv", 7)
  )
  pd_upload(local, name = "renamed.csv", thumbnails = FALSE)
  expect_equal(basename(seen), "renamed.csv")
  expect_false(file.exists(seen))
})

test_that("pd_upload() stages renamed folders", {
  withr::local_options(protondrive_quiet = FALSE)
  dir <- withr::local_tempdir()
  writeLines("x", file.path(dir, "f.txt"))
  local_fake_cli(
    "filesystem upload" = function(pos, ...) {
      expect_equal(basename(pos[[1]]), "renamed")
      expect_equal(list.files(pos[[1]]), "f.txt")
      list(transferredItems = 2)
    },
    "filesystem info" = fake_node("renamed", 7, type = "folder")
  )
  expect_message(pd_upload(dir, name = "renamed"), "Uploaded")
})

test_that("pd_put() and overwrite = TRUE create new revisions", {
  local <- withr::local_tempfile()
  writeLines("x", local)
  log <- local_fake_cli(
    "filesystem upload" = list(transferredItems = 1),
    "filesystem info" = fake_node("f", 7)
  )
  pd_put(local, thumbnails = FALSE)
  upload <- log$calls[[1]]
  expect_equal(option_value(upload, "file-conflict-strategy"), "create-new-revision")
  expect_equal(option_value(upload, "folder-conflict-strategy"), "merge")
  expect_true("--skip-thumbnails" %in% upload)
})

test_that("pd_upload() reports identical content", {
  withr::local_options(protondrive_quiet = FALSE)
  local <- withr::local_tempfile()
  writeLines("x", local)
  local_fake_cli(
    "filesystem upload" = list(transferredItems = 0, skippedItems = 1),
    "filesystem info" = fake_node("f", 7)
  )
  expect_message(pd_upload(local), "identical content")
})

test_that("pd_update() uploads into the file's parent under its name", {
  local <- withr::local_tempfile()
  writeLines("x", local)
  log <- local_fake_cli(
    "filesystem upload" = list(transferredItems = 1),
    "filesystem info" = fake_node("a.csv", 1, parent = 3)
  )
  file <- fake_dribble("a.csv", 1, parent = 3, path = "/my-files/data/a.csv")
  x <- pd_update(file, local)
  upload <- log$calls[[1]]
  expect_equal(basename(positional(upload)[[1]]), "a.csv")
  expect_equal(positional(upload)[[2]], paste0("/my-files/", fake_uid(3)))
  expect_equal(x$path, "/my-files/data/a.csv")

  folder <- fake_dribble("data", 3, type = "folder")
  expect_error(pd_update(folder, local), "must be a file")
})

test_that("pd_upload() validates media", {
  expect_error(pd_upload("does-not-exist.csv"), "does not exist")
  expect_error(pd_upload(c("a", "b")), "single")
})

test_that("format_bytes() is human readable", {
  expect_equal(format_bytes(0), "0 B")
  expect_equal(format_bytes(512), "512 B")
  expect_equal(format_bytes(2048), "2.00 KiB")
  expect_equal(format_bytes(3 * 1024^3), "3.00 GiB")
})
