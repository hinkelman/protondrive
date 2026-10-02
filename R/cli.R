#' Locate the Proton Drive CLI
#'
#' @description
#' protondrive does not talk to the Proton Drive API directly. Encryption,
#' sessions, caching, and API traffic are all handled by the official Proton
#' Drive command-line interface (`proton-drive`), which is built on the
#' [Proton Drive SDK](https://github.com/ProtonDriveApps/sdk). These functions
#' report which executable protondrive will use and which version it is.
#'
#' The executable is found by checking, in order:
#'
#' 1. The `protondrive.cli_path` option.
#' 2. The `PROTONDRIVE_CLI_PATH` environment variable.
#' 3. `proton-drive` on the `PATH`.
#'
#' Download the CLI from <https://proton.me/download/drive/cli/index.html>.
#'
#' @return
#' * `pd_cli_path()`: The path to the executable, as a string.
#' * `pd_cli_version()`: The version text reported by the CLI, invisibly.
#'   It is also printed.
#' * `pd_has_cli()`: `TRUE` or `FALSE`.
#' @export
#' @examples
#' pd_has_cli()
#' if (pd_has_cli()) pd_cli_path()
pd_cli_path <- function() {
  candidates <- c(
    getOption("protondrive.cli_path", default = ""),
    Sys.getenv("PROTONDRIVE_CLI_PATH"),
    Sys.which("proton-drive")
  )
  candidates <- candidates[nzchar(candidates)]
  for (candidate in candidates) {
    if (file.exists(candidate)) {
      return(normalizePath(candidate, mustWork = TRUE))
    }
  }
  cli::cli_abort(
    c(
      "Can't find the Proton Drive CLI ({.code proton-drive}).",
      "i" = "Download it from {.url https://proton.me/download/drive/cli/index.html}.",
      "i" = "Then put it on your {.envvar PATH}, or set the
             {.envvar PROTONDRIVE_CLI_PATH} environment variable or the
             {.code protondrive.cli_path} option to its location."
    ),
    class = "protondrive_cli_missing"
  )
}

#' @rdname pd_cli_path
#' @export
pd_has_cli <- function() {
  tryCatch(
    {
      pd_cli_path()
      TRUE
    },
    protondrive_cli_missing = function(e) FALSE
  )
}

#' @rdname pd_cli_path
#' @export
pd_cli_version <- function() {
  out <- pd_run_cli("version")
  check_cli_status(out, "version")
  text <- trimws(out$stdout)
  cat(text, "\n", sep = "")
  invisible(text)
}

# The single boundary between R and the CLI process. Everything else in the
# package goes through here, which makes it the one thing tests need to mock.
pd_run_cli <- function(args, echo = FALSE) {
  processx::run(
    command = pd_cli_path(),
    args = args,
    error_on_status = FALSE,
    echo = echo,
    encoding = "UTF-8",
    windows_hide_window = TRUE
  )
}

# Run `proton-drive <group> <command> [options] -- [positionals]`. Options are
# a named list; `TRUE` becomes a bare flag, `FALSE`/`NULL` is dropped, and
# vectors repeat the flag. Positionals go after `--` so names beginning with a
# dash are never mistaken for options.
pd_cli <- function(group, command, args = character(), options = list(),
                   json = TRUE, parse = json, call = rlang::caller_env()) {
  argv <- c(group, command, cli_options(options))
  if (json) {
    argv <- c(argv, "--json")
  }
  if (length(args) > 0) {
    argv <- c(argv, "--", args)
  }

  out <- pd_run_cli(argv)
  check_cli_status(out, paste(group, command), call = call)

  if (!parse) {
    return(invisible(out$stdout))
  }
  parse_cli_json(out$stdout, call = call)
}

cli_options <- function(options) {
  argv <- character()
  for (nm in names(options)) {
    value <- options[[nm]]
    if (is.null(value) || isFALSE(value)) {
      next
    }
    flag <- paste0("--", nm)
    if (isTRUE(value)) {
      argv <- c(argv, flag)
    } else {
      for (v in as.character(value)) {
        argv <- c(argv, flag, v)
      }
    }
  }
  argv
}

check_cli_status <- function(out, what, call = rlang::caller_env()) {
  if (identical(as.integer(out$status), 0L)) {
    return(invisible(out))
  }

  message <- cli_error_message(out$stderr)
  details <- transfer_failures(out$stdout)

  if (grepl("login first", message, fixed = TRUE)) {
    cli::cli_abort(
      c(
        "You are not signed in to Proton Drive.",
        "i" = "Call {.fun pd_auth} to sign in."
      ),
      class = c("protondrive_auth_error", "protondrive_error"),
      call = call
    )
  }

  cli::cli_abort(
    c(
      "{.code proton-drive {what}} failed.",
      "x" = "{message}",
      details
    ),
    class = "protondrive_error",
    stderr = out$stderr,
    stdout = out$stdout,
    status = out$status,
    call = call
  )
}

# The CLI prints a single message line for expected errors, but a banner and
# stack trace for unexpected ones. Take the first informative line.
cli_error_message <- function(stderr) {
  lines <- trimws(strsplit(stderr %||% "", "\n", fixed = TRUE)[[1]])
  lines <- lines[nzchar(lines)]
  lines <- lines[!grepl("^=+$", lines)]
  lines <- lines[!grepl("^at ", lines)]
  if (length(lines) == 0) {
    return("Unknown error (the CLI produced no error message).")
  }
  sub("^(Trace|Error): ", "", lines[[1]])
}

# Upload and download print a JSON summary to stdout even when they fail.
transfer_failures <- function(stdout) {
  summary <- tryCatch(parse_cli_json(stdout), error = function(e) NULL)
  failures <- if (is.list(summary)) summary$failures else NULL
  if (length(failures) == 0) {
    return(character())
  }
  msgs <- vapply(
    failures,
    function(f) paste0(f$name %||% "?", ": ", f$error %||% "unknown error"),
    character(1)
  )
  rlang::set_names(msgs, rep("*", length(msgs)))
}

parse_cli_json <- function(text, call = rlang::caller_env()) {
  text <- trimws(text %||% "")
  if (!nzchar(text)) {
    return(NULL)
  }
  if (jsonlite::validate(text)) {
    return(jsonlite::parse_json(text, simplifyVector = FALSE))
  }

  # Some commands can print a human-readable notice alongside the JSON
  # payload. Fall back to the last line that is valid JSON on its own.
  lines <- rev(strsplit(text, "\n", fixed = TRUE)[[1]])
  for (line in lines) {
    if (grepl("^\\s*[\\[{]", line) && jsonlite::validate(line)) {
      return(jsonlite::parse_json(line, simplifyVector = FALSE))
    }
  }
  cli::cli_abort(
    "Can't parse the output of the Proton Drive CLI as JSON.",
    class = "protondrive_error",
    stdout = text,
    call = call
  )
}
