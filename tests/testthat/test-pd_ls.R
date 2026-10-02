test_that("pd_ls() lists a folder and builds child paths", {
  log <- local_fake_cli("filesystem list" = list(
    fake_node("a.csv", 1), fake_node("sub", 2, type = "folder"), fake_node("x/y.txt", 3)
  ))
  x <- pd_ls("data")
  expect_equal(positional(log$calls[[1]]), "/my-files/data")
  expect_equal(x$name, c("a.csv", "sub", "x/y.txt"))
  expect_equal(x$path, c("/my-files/data/a.csv", "/my-files/data/sub", "/my-files/data/x\\/y.txt"))
})

test_that("pd_ls() defaults to /my-files and filters", {
  log <- local_fake_cli("filesystem list" = list(
    fake_node("a.csv", 1), fake_node("b.txt", 2), fake_node("sub", 3, type = "folder")
  ))
  expect_equal(pd_ls(pattern = "csv$")$name, "a.csv")
  expect_equal(pd_ls(type = "folder")$name, "sub")
  expect_equal(positional(log$calls[[1]]), "/my-files")
})

test_that("pd_ls() recurses into folders by ID", {
  log <- local_fake_cli("filesystem list" = function(pos, ...) {
    if (pos == "/my-files") {
      list(fake_node("a.csv", 1), fake_node("sub", 2, type = "folder"))
    } else {
      expect_equal(pos, paste0("/my-files/", fake_uid(2)))
      list(fake_node("b.csv", 3, parent = 2))
    }
  })
  x <- pd_ls(recursive = TRUE)
  expect_equal(x$name, c("a.csv", "sub", "b.csv"))
  expect_equal(x$path[[3]], "/my-files/sub/b.csv")
  expect_equal(pd_ls(recursive = TRUE, type = "file")$name, c("a.csv", "b.csv"))
})

test_that("pd_ls('/') lists sections", {
  local_fake_cli("filesystem list" = list(list(path = "/my-files"), list(path = "/trash")))
  x <- pd_ls("/")
  expect_equal(x$name, c("my-files", "trash"))
  expect_equal(x$path, c("/my-files", "/trash"))
  expect_equal(pd_address(x), c("/my-files", "/trash"))
})

test_that("pd_ls('/devices') lists devices", {
  local_fake_cli("filesystem list" = list(list(
    uid = "dev1", type = "Linux", name = list(ok = TRUE, value = "laptop"),
    rootFolderUid = fake_uid(9), creationTime = "2026-01-01T00:00:00.000Z"
  )))
  x <- pd_ls("/devices")
  expect_equal(x$name, "laptop")
  expect_equal(x$path, "/devices/laptop")
  expect_equal(vctrs::vec_data(x$id), fake_uid(9))
})

test_that("pd_ls() gives shared-by-me items no path, trash items a trash path", {
  local_fake_cli("filesystem list" = list(fake_node("a.csv", 1)))
  expect_true(is.na(pd_ls("/shared-by-me")$path))
  expect_equal(pd_ls("/trash")$path, "/trash/a.csv")
  expect_equal(pd_ls("/shared-with-me")$path, "/shared-with-me/a.csv")
})

test_that("pd_ls() accepts a dribble folder", {
  log <- local_fake_cli("filesystem list" = list(fake_node("b", 2)))
  folder <- fake_dribble("data", 1, type = "folder")
  x <- pd_ls(folder)
  expect_equal(positional(log$calls[[1]]), paste0("/my-files/", fake_uid(1)))
  expect_equal(x$path, "/my-files/data/b")
  expect_error(pd_ls(c("a", "b")), "exactly one")
})

test_that("pd_ls() returns an empty dribble for an empty folder", {
  local_fake_cli("filesystem list" = "[\n\n]\n")
  x <- pd_ls()
  expect_true(is_dribble(x))
  expect_equal(nrow(x), 0)
  expect_equal(nrow(pd_ls(type = "file")), 0)
})
