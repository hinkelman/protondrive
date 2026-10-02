test_that("as_id() marks strings and extracts ids", {
  id <- as_id(fake_uid(1))
  expect_s3_class(id, "pd_id")
  expect_identical(as_id(id), id)
  expect_equal(vctrs::vec_data(as_id(fake_dribble("a", 1))), fake_uid(1))
  expect_null(as_id(NULL))
  expect_error(as_id(1), "Don't know how")
  expect_error(as_id(data.frame(x = 1)), "id")
})

test_that("is_node_uid() matches the CLI's UID format", {
  expect_true(is_node_uid(fake_uid(1)))
  long <- paste0(strrep("A", 88), "~", strrep("b", 100))
  expect_true(is_node_uid(long))
  expect_false(is_node_uid("reports"))
  expect_false(is_node_uid(NA))
  expect_false(is_node_uid("short~id"))
})

test_that("pd_id prints and abbreviates", {
  expect_snapshot(print(as_id(fake_uid(1))))
  expect_equal(abbreviate_id(strrep("x", 10)), strrep("x", 10))
  expect_equal(nchar(abbreviate_id(strrep("x", 100))), 24)
})
