#' Silence protondrive messages
#'
#' @description
#' protondrive reports what it did, such as "Uploaded x to y". To silence
#' these messages, set the option `protondrive_quiet = TRUE`, or use these
#' helpers, which mirror [googledrive::local_drive_quiet()] and
#' [googledrive::with_drive_quiet()]. Errors and warnings are never
#' silenced.
#'
#' @param env The environment whose exit ends the quiet period.
#' @param code Code to run quietly.
#'
#' @return `with_pd_quiet()` returns the result of `code`.
#' @export
#' @examples
#' \dontrun{
#' with_pd_quiet(pd_upload("mtcars.csv"))
#'
#' f <- function() {
#'   local_pd_quiet()
#'   pd_mkdir("scratch")
#' }
#' }
local_pd_quiet <- function(env = parent.frame()) {
  withr::local_options(protondrive_quiet = TRUE, .local_envir = env)
}

#' @rdname local_pd_quiet
#' @export
with_pd_quiet <- function(code) {
  withr::with_options(list(protondrive_quiet = TRUE), code)
}

pd_quiet <- function() {
  isTRUE(getOption("protondrive_quiet", default = FALSE))
}

pd_inform <- function(message, .envir = parent.frame()) {
  if (pd_quiet()) {
    return(invisible())
  }
  cli::cli_inform(message, .envir = .envir)
}
