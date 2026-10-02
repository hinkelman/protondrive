test_that("pd_cp() copies alongside the original by default", {
  log <- local_fake_cli(
    "filesystem info" = function(pos, ...) {
      if (grepl("Copy of", pos)) cli_fail("Node not found") else fake_node("Copy of a.csv", 8)
    },
    "filesystem copy" = list(list(uid = fake_uid(1), newUid = fake_uid(8), ok = TRUE))
  )
  file <- fake_dribble("a.csv", 1, parent = 3, path = "/my-files/data/a.csv")
  x <- pd_cp(file)
  copy <- log$calls[[2]]
  expect_equal(positional(copy), c(paste0("/my-files/", fake_uid(1)), paste0("/my-files/", fake_uid(3))))
  expect_equal(option_value(copy, "name"), "Copy of a.csv")
  expect_equal(x$path, "/my-files/data/Copy of a.csv")
  expect_equal(vctrs::vec_data(x$id), fake_uid(8))
})

test_that("pd_cp() into another folder keeps the name", {
  log <- local_fake_cli(
    "filesystem info" = function(pos, ...) {
      if (endsWith(pos, "/a.csv")) cli_fail("Node not found") else fake_node("a.csv", 8)
    },
    "filesystem copy" = list(list(uid = fake_uid(1), newUid = fake_uid(8), ok = TRUE))
  )
  x <- pd_cp(fake_dribble("a.csv", 1), path = "archive")
  expect_equal(option_value(log$calls[[2]], "name"), "a.csv")
  expect_equal(x$path, "/my-files/archive/a.csv")
})

test_that("failed bulk results become errors", {
  local_fake_cli(
    "filesystem info" = cli_fail("Node not found"),
    "filesystem copy" = list(list(uid = fake_uid(1), ok = FALSE, error = list()))
  )
  expect_snapshot(pd_cp(fake_dribble("a.csv", 1), path = "archive"), error = TRUE)
  expect_equal(node_error_message(list(message = "Quota exceeded")), "Quota exceeded")
  expect_equal(node_error_message("x"), "x")
})

test_that("pd_rename() renames in place", {
  log <- local_fake_cli(
    "filesystem info" = cli_fail("Node not found"),
    "filesystem rename" = function(pos, ...) fake_node(pos[[2]], 1)
  )
  file <- fake_dribble("a.csv", 1, parent = 3, path = "/my-files/data/a.csv")
  x <- pd_rename(file, "b.csv")
  expect_equal(positional(log$calls[[1]]), paste0("/my-files/", fake_uid(3), "/b.csv"))
  expect_equal(positional(log$calls[[2]]), c(paste0("/my-files/", fake_uid(1)), "b.csv"))
  expect_equal(x$name, "b.csv")
  expect_equal(x$path, "/my-files/data/b.csv")
})

test_that("pd_rename() refuses name clashes", {
  local_fake_cli("filesystem info" = fake_node("b.csv", 2))
  file <- fake_dribble("a.csv", 1, parent = 3)
  expect_error(pd_rename(file, "b.csv"), class = "protondrive_conflict")
})

test_that("pd_mv() moves, then reports the new location", {
  log <- local_fake_cli(
    "filesystem info" = function(pos, ...) {
      if (endsWith(pos, "/a.csv")) cli_fail("Node not found") else fake_node("a.csv", 1, parent = 4)
    },
    "filesystem move" = node_results(fake_uid(1))
  )
  file <- fake_dribble("a.csv", 1, parent = 3, path = "/my-files/data/a.csv")
  x <- pd_mv(file, path = "archive")
  expect_equal(
    positional(log$calls[[2]]),
    c(paste0("/my-files/", fake_uid(1)), "/my-files/archive")
  )
  expect_equal(x$path, "/my-files/archive/a.csv")
  expect_error(pd_mv(file), "Supply a new")
})

test_that("pd_mv() can rename and move together", {
  log <- local_fake_cli(
    "filesystem info" = function(pos, ...) {
      if (endsWith(pos, "/b.csv")) cli_fail("Node not found") else fake_node("b.csv", 1, parent = 4)
    },
    "filesystem rename" = function(pos, ...) fake_node(pos[[2]], 1, parent = 3),
    "filesystem move" = node_results(fake_uid(1))
  )
  file <- fake_dribble("a.csv", 1, parent = 3, path = "/my-files/data/a.csv")
  x <- pd_mv(file, path = "archive", name = "b.csv")
  commands <- vapply(log$calls, function(a) a[[2]], "")
  expect_equal(commands, c("info", "rename", "info", "move", "info"))
  expect_equal(x$path, "/my-files/archive/b.csv")
  expect_equal(x$name, "b.csv")
})
