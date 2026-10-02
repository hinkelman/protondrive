test_that("normalize_path() anchors relative paths in /my-files", {
  expect_equal(
    normalize_path(c("~", "", "~/a", "a/b", "/shared-with-me/x/", "/", "/my-files//a")),
    c("/my-files", "/my-files", "/my-files/a", "/my-files/a/b",
      "/shared-with-me/x", "/", "/my-files/a")
  )
})

test_that("normalize_path() rejects unknown sections", {
  expect_snapshot(normalize_path("/nope/a"), error = TRUE)
})

test_that("escaped slashes stay inside names", {
  path <- "/my-files/a\\/b/c"
  expect_equal(path_segments(path)[[1]], c("my-files", "a/b", "c"))
  expect_equal(path_basename(path), "c")
  expect_equal(path_parent(path), "/my-files/a\\/b")
  expect_equal(path_join("/my-files", "x/y"), "/my-files/x\\/y")
  expect_equal(path_section(c("/", "/trash/a", NA)), c(NA, "trash", NA))
  expect_equal(path_parent("/my-files"), "/")
})

test_that("pd_address() prefers IDs for drive nodes", {
  x <- dribble_rbind(list(
    fake_dribble("a.csv", 1),
    fake_dribble("b.csv", 2, path = "/trash/b.csv"),
    fake_dribble("c.jpg", 3, path = "/photos/c.jpg"),
    dribble(name = "my-files", path = "/my-files")
  ))
  expect_equal(
    pd_address(x),
    c(paste0("/my-files/", fake_uid(1)), "/trash/b.csv",
      paste0("/photos/", fake_uid(3)), "/my-files")
  )
})
