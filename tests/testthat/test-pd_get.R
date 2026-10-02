test_that("pd_get() looks up paths", {
  log <- local_fake_cli("filesystem info" = function(pos, ...) {
    fake_node(path_basename(pos), 1)
  })
  x <- pd_get("data/a.csv")
  expect_equal(positional(log$calls[[1]]), "/my-files/data/a.csv")
  expect_equal(x$name, "a.csv")
  expect_equal(x$path, "/my-files/data/a.csv")
  expect_equal(vctrs::vec_data(x$id), fake_uid(1))
})

test_that("pd_get() looks up IDs", {
  log <- local_fake_cli("filesystem info" = fake_node("a.csv", 1))
  x <- pd_get(id = fake_uid(1))
  expect_equal(positional(log$calls[[1]]), paste0("/my-files/", fake_uid(1)))
  expect_true(is.na(x$path))

  y <- pd_get(as_id(fake_uid(1)))
  expect_equal(y$name, "a.csv")
})

test_that("pd_get() is vectorised and validates input", {
  local_fake_cli("filesystem info" = function(pos, ...) fake_node(path_basename(pos), 1))
  expect_equal(pd_get(c("a", "b"))$name, c("a", "b"))
  expect_error(pd_get(), "exactly one")
  expect_error(pd_get("a", id = "b"), "exactly one")
  expect_error(pd_get(id = "nope"), "valid node ID")
})

test_that("character input to other functions goes through pd_get()", {
  local_fake_cli("filesystem info" = fake_node("a.csv", 1))
  x <- as_dribble("a.csv")
  expect_equal(x$path, "/my-files/a.csv")
})
