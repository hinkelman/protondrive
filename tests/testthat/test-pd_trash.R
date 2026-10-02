test_that("pd_trash() trashes by ID and points paths into the trash", {
  log <- local_fake_cli("filesystem trash" = node_results(c(fake_uid(1), fake_uid(2))))
  x <- dribble_rbind(list(fake_dribble("a", 1), fake_dribble("b", 2)))
  out <- pd_trash(x)
  expect_equal(positional(log$calls[[1]]), paste0("/my-files/", c(fake_uid(1), fake_uid(2))))
  expect_equal(out$path, c("/trash/a", "/trash/b"))
})

test_that("pd_untrash() verifies the name refers to the right node", {
  log <- local_fake_cli(
    "filesystem list" = list(fake_node("a", 1), fake_node("b", 2)),
    "filesystem restore" = node_results(fake_uid(1)),
    "filesystem info" = fake_node("a", 1)
  )
  out <- pd_untrash(fake_dribble("a", 1, path = "/trash/a"))
  expect_equal(positional(log$calls[[2]]), "/trash/a")
  expect_true(is.na(out$path))
})

test_that("pd_untrash() refuses ambiguous or mismatched names", {
  local_fake_cli("filesystem list" = list(fake_node("a", 1), fake_node("a", 5)))
  expect_snapshot(pd_untrash(fake_dribble("a", 1, path = "/trash/a")), error = TRUE)

  local_fake_cli("filesystem list" = list(fake_node("a", 9)))
  expect_error(pd_untrash(fake_dribble("a", 1, path = "/trash/a")), "not the one")

  local_fake_cli("filesystem list" = list())
  expect_error(pd_untrash(fake_dribble("a", 1, path = "/trash/a")), "not in")
})

test_that("pd_rm() trashes first, then deletes", {
  log <- local_fake_cli(
    "filesystem trash" = node_results(fake_uid(1)),
    "filesystem list" = list(fake_node("a", 1), fake_node("old", 2)),
    "filesystem delete" = node_results(c(fake_uid(1), fake_uid(2)))
  )
  x <- dribble_rbind(list(fake_dribble("a", 1), fake_dribble("old", 2, path = "/trash/old")))
  pd_rm(x)
  commands <- vapply(log$calls, function(a) a[[2]], "")
  expect_equal(commands, c("trash", "list", "delete"))
  expect_equal(positional(log$calls[[1]]), paste0("/my-files/", fake_uid(1)))
  expect_equal(positional(log$calls[[3]]), c("/trash/a", "/trash/old"))
})

test_that("photos go to the photos trash", {
  x <- fake_dribble("p.jpg", 1, path = "/photos/p.jpg", type = "photo")
  expect_equal(trash_path(x), "/photos-trash/p.jpg")
})

test_that("pd_empty_trash() calls the CLI", {
  withr::local_options(protondrive_quiet = FALSE)
  log <- local_fake_cli("filesystem empty-trash" = "")
  expect_message(pd_empty_trash(), "Emptied")
  expect_equal(log$calls[[1]], c("filesystem", "empty-trash", "--json"))
})

test_that("empty input is a no-op", {
  log <- local_fake_cli()
  expect_equal(nrow(pd_trash(new_dribble())), 0)
  expect_equal(nrow(pd_untrash(new_dribble())), 0)
  expect_equal(nrow(pd_rm(new_dribble())), 0)
  expect_length(log$calls, 0)
})
