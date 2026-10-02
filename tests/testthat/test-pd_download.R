# The fake download writes `content` under the node's name in the folder the
# CLI is given, as the real CLI does. It writes bytes, not text, so the
# content is identical on every platform (`writeLines()` would use CRLF line
# endings on Windows).
fake_download <- function(name, content = "hello") {
  function(pos, ...) {
    bytes <- charToRaw(paste0(content, "\n", collapse = ""))
    writeBin(bytes, file.path(pos[[2]], name))
    list(transferredItems = 1, transferredBytes = 6, skippedItems = 0)
  }
}

test_that("pd_download() saves to the requested path", {
  dir <- withr::local_tempdir()
  dest <- file.path(dir, "out.txt")
  log <- local_fake_cli("filesystem download" = fake_download("a.txt"))
  file <- fake_dribble("a.txt", 1)
  x <- pd_download(file, path = dest)
  expect_equal(readLines(dest), "hello")
  expect_equal(positional(log$calls[[1]])[[1]], paste0("/my-files/", fake_uid(1)))
  expect_equal(x$local_path, normalizePath(dest))
  expect_false(dir.exists(positional(log$calls[[1]])[[2]]))
})

test_that("pd_download() defaults to the file name in the working directory", {
  dir <- withr::local_tempdir()
  withr::local_dir(dir)
  local_fake_cli("filesystem download" = fake_download("a.txt"))
  pd_download(fake_dribble("a.txt", 1))
  expect_true(file.exists(file.path(dir, "a.txt")))
})

test_that("pd_download() won't overwrite unless asked", {
  dest <- withr::local_tempfile()
  writeLines("old", dest)
  log <- local_fake_cli("filesystem download" = fake_download("a.txt", "new"))
  file <- fake_dribble("a.txt", 1)
  expect_error(pd_download(file, path = dest), "already exists")
  expect_length(log$calls, 0)
  pd_download(file, path = dest, overwrite = TRUE)
  expect_equal(readLines(dest), "new")
})

test_that("pd_download() downloads folders", {
  dir <- withr::local_tempdir()
  local_fake_cli("filesystem download" = function(pos, ...) {
    dir.create(file.path(pos[[2]], "data"))
    writeLines("x", file.path(pos[[2]], "data", "f.txt"))
    list(transferredItems = 2)
  })
  pd_download(fake_dribble("data", 1, type = "folder"), path = file.path(dir, "copy"))
  expect_equal(list.files(file.path(dir, "copy")), "f.txt")
})

test_that("pd_download() explains skipped Proton Docs", {
  local_fake_cli("filesystem download" = list(transferredItems = 0, skippedItems = 1))
  dest <- withr::local_tempfile()
  expect_error(pd_download(fake_dribble("doc", 1), path = dest), "Proton Docs")
})

test_that("pd_read_string() and pd_read_raw() return content", {
  local_fake_cli("filesystem download" = fake_download("a.txt", c("x,y", "1,2")))
  file <- fake_dribble("a.txt", 1)
  expect_equal(pd_read_string(file), "x,y\n1,2\n")
  expect_equal(pd_read_raw(file), charToRaw("x,y\n1,2\n"))
  expect_error(pd_read_raw(fake_dribble("d", 2, type = "folder")), "only read files")
})
