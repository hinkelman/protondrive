test_that("dribbles are tibbles with the expected columns", {
  x <- fake_dribble("a.csv", 1)
  expect_s3_class(x, c("pd_dribble", "tbl_df", "tbl", "data.frame"))
  # A distinct class keeps googledrive's "dribble" methods from applying.
  expect_false(inherits(x, "dribble"))
  expect_named(x, c("name", "path", "id", "drive_resource"))
  expect_s3_class(x$id, "pd_id")
  expect_true(is_dribble(x))
  expect_false(is_dribble(mtcars))
})

test_that("an empty dribble has the right shape", {
  x <- new_dribble()
  expect_equal(nrow(x), 0)
  expect_named(x, c("name", "path", "id", "drive_resource"))
  expect_true(is_dribble(as_dribble(NULL)))
})

test_that("subsetting keeps the class only while the columns survive", {
  x <- dribble_rbind(list(fake_dribble("a", 1), fake_dribble("b", 2)))
  expect_true(is_dribble(x[1, ]))
  expect_true(is_dribble(x[x$name == "b", ]))
  expect_false(is_dribble(x[, c("name", "path")]))
  y <- x
  names(y)[1] <- "nm"
  expect_false(is_dribble(y))
})

test_that("dribbles print with their own header", {
  x <- fake_dribble("a.csv", 1)
  expect_match(format(x)[[1]], "A dribble: 1 .* 4")
})

test_that("as_dribble() validates data frames", {
  x <- fake_dribble("a.csv", 1)
  df <- tibble::as_tibble(x)
  class(df) <- c("tbl_df", "tbl", "data.frame")
  expect_true(is_dribble(as_dribble(df)))
  expect_snapshot(as_dribble(data.frame(name = "a")), error = TRUE)
  expect_error(as_dribble(1), "Don't know how")
})

test_that("dribbles combine with vctrs", {
  x <- vctrs::vec_rbind(fake_dribble("a", 1), fake_dribble("b", 2))
  expect_true(is_dribble(x))
  expect_equal(x$name, c("a", "b"))
  y <- vctrs::vec_rbind(fake_dribble("a", 1), tibble::tibble(name = "z"))
  expect_false(is_dribble(y))
})

test_that("dribbles survive dplyr verbs that keep the columns", {
  skip_if_not_installed("dplyr")
  x <- dribble_rbind(list(fake_dribble("a", 1), fake_dribble("b", 2)))
  expect_true(is_dribble(dplyr::filter(x, name == "a")))
  expect_true(is_dribble(dplyr::arrange(x, dplyr::desc(name))))
  expect_true(is_dribble(dplyr::mutate(x, n = nchar(name))))
  expect_false(is_dribble(dplyr::select(x, name)))
})

test_that("node names follow the CLI's fallbacks", {
  expect_equal(node_name(list(uid = "u", name = list(ok = TRUE, value = "a"))), "a")
  expect_equal(
    node_name(list(uid = "u", name = list(ok = FALSE, error = list(name = "placeholder", error = "bad")))),
    "placeholder"
  )
  expect_equal(node_name(list(uid = "u", name = list(ok = FALSE, error = list()))), "u")
  expect_equal(node_name(list(uid = "u", name = list(ok = TRUE, value = ""))), "u")
})
