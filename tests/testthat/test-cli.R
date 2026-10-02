test_that("options become flags, and positionals follow `--`", {
  log <- local_fake_cli("filesystem list" = list())
  pd_cli("filesystem", "list", "-odd name", options = list(
    type = "file", skip = NULL, quiet = FALSE, flag = TRUE, user = c("a", "b")
  ))
  expect_equal(
    log$calls[[1]],
    c("filesystem", "list", "--type", "file", "--flag",
      "--user", "a", "--user", "b", "--json", "--", "-odd name")
  )
})

test_that("CLI errors become protondrive_error conditions", {
  local_fake_cli("filesystem info" = cli_fail("Node not found: nope"))
  expect_error(pd_cli("filesystem", "info", "/my-files/nope"), class = "protondrive_error")
  expect_snapshot(pd_cli("filesystem", "info", "/my-files/nope"), error = TRUE)
})

test_that("a missing session becomes a protondrive_auth_error", {
  local_fake_cli("filesystem list" = cli_fail("You need to login first"))
  expect_error(pd_cli("filesystem", "list", "/"), class = "protondrive_auth_error")
  expect_false(pd_has_auth())
})

test_that("pd_has_auth() is TRUE when the CLI runs", {
  local_fake_cli("filesystem list" = list(list(path = "/my-files")))
  expect_true(pd_has_auth())
})

test_that("unexpected errors report the first informative line", {
  stderr <- "===============================================\nTrace: TypeError: boom\n    at foo (bar.ts:1)\n"
  expect_equal(cli_error_message(stderr), "TypeError: boom")
  expect_match(cli_error_message(""), "no error message")
})

test_that("transfer failures are listed in the error", {
  summary <- to_json(list(
    transferredItems = 0, transferredBytes = 0, skippedItems = 0, failedItems = 1,
    failures = list(list(name = "a.csv", error = "ValidationError: Name conflict"))
  ))
  local_fake_cli("filesystem upload" = cli_fail("1 item(s) failed to upload", stdout = summary))
  expect_snapshot(pd_cli("filesystem", "upload", c("a.csv", "/my-files")), error = TRUE)
})

test_that("JSON parsing tolerates a notice before the payload", {
  expect_equal(parse_cli_json("Some notice\n{\"a\":1}"), list(a = 1L))
  expect_null(parse_cli_json(""))
  expect_equal(parse_cli_json("[\n\n]\n"), list())
})

test_that("pd_cli_path() finds the CLI from the option or errors helpfully", {
  exe <- withr::local_tempfile()
  writeLines("", exe)
  withr::local_options(protondrive.cli_path = exe)
  expect_equal(pd_cli_path(), normalizePath(exe))

  withr::local_options(protondrive.cli_path = NULL)
  withr::local_envvar(PROTONDRIVE_CLI_PATH = "", PATH = "")
  expect_error(pd_cli_path(), class = "protondrive_cli_missing")
  expect_false(pd_has_cli())
})

test_that("quiet mode silences status messages but not errors", {
  withr::local_options(protondrive_quiet = FALSE)
  expect_message(pd_inform("hello"), "hello")
  expect_silent(with_pd_quiet(pd_inform("hello")))
  f <- function() {
    local_pd_quiet()
    pd_inform("hello")
  }
  expect_silent(f())
  expect_message(pd_inform("hello"), "hello")
})

test_that("the literal `undefined` printed by the CLI parses as NULL", {
  expect_null(parse_cli_json("undefined\n"))
})
