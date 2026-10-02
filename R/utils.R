check_string <- function(x, arg, call = rlang::caller_env()) {
  if (!rlang::is_string(x) || !nzchar(x)) {
    cli::cli_abort("{.arg {arg}} must be a single, non-empty string.", call = call)
  }
  invisible(x)
}
