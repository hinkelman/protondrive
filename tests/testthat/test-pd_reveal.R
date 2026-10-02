test_that("pd_reveal() adds columns after name", {
  x <- dribble_rbind(list(
    fake_dribble("a.csv", 1, size = 1234, shared = TRUE),
    fake_dribble("sub", 2, type = "folder")
  ))
  y <- pd_reveal(x, c("type", "size", "modified_time", "shared", "sha1", "parent_id"))
  expect_true(is_dribble(y))
  expect_named(y, c("name", "type", "size", "modified_time", "shared", "sha1",
                    "parent_id", "path", "id", "drive_resource"))
  expect_equal(y$type, c("file", "folder"))
  expect_equal(y$size, c(1234, NA))
  expect_equal(y$shared, c(TRUE, FALSE))
  expect_s3_class(y$modified_time, "POSIXct")
  expect_equal(format(y$modified_time[[1]], "%H:%M", tz = "UTC"), "11:30")
  expect_equal(y$sha1[[2]], NA_character_)
  expect_s3_class(y$parent_id, "pd_id")
})

test_that("pd_reveal() supports every documented field", {
  x <- fake_dribble("a.csv", 1)
  y <- pd_reveal(x, names(reveal_fields))
  expect_equal(ncol(y), 4 + length(reveal_fields))
  expect_equal(y$owner, "me@proton.me")
  expect_equal(y$author, "me@proton.me")
  expect_error(pd_reveal(x, "nope"))
})

test_that("pd_reveal() works on an empty dribble", {
  y <- pd_reveal(new_dribble(), c("size", "modified_time"))
  expect_equal(nrow(y), 0)
})

test_that("unverified authors are shown in parentheses", {
  expect_equal(author_email(list(ok = FALSE, error = list(claimedAuthor = "x@y.z", error = "bad"))), "(x@y.z)")
  expect_equal(author_email(list(ok = TRUE, value = NULL)), NA_character_)
})
