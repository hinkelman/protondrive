#' Sign in to Proton Drive
#'
#' @description
#' `pd_auth()` signs you in to Proton Drive. It opens a browser window where
#' you sign in with your Proton account, and waits until you finish. You can
#' also open the printed URL on another device.
#'
#' Your password never passes through R. The session is created and stored
#' by the Proton Drive CLI, in your operating system's secret store
#' (Keychain, Windows Credential Manager, or libsecret), and persists across
#' R sessions. You usually only need to sign in once per machine.
#'
#' *This is a third-party application not officially supported by Proton.*
#'
#' @details
#' Where the CLI stores the session is controlled by the
#' `PROTON_DRIVE_CREDENTIALS_STORE` environment variable (`keychain`, the
#' default, or `pass`). See the CLI's documentation for details.
#'
#' @param force If `TRUE`, sign in again even if a session already exists.
#'
#' @return
#' * `pd_auth()`, `pd_deauth()`: `NULL`, invisibly.
#' * `pd_has_auth()`: `TRUE` if a usable session exists, `FALSE` otherwise.
#' @export
#' @examples
#' \dontrun{
#' pd_auth()
#' pd_has_auth()
#' pd_deauth()
#' }
pd_auth <- function(force = FALSE) {
  if (!force && pd_has_auth()) {
    cli::cli_inform("Already signed in to Proton Drive.")
    return(invisible())
  }
  if (!rlang::is_interactive()) {
    cli::cli_abort(c(
      "Signing in requires an interactive session.",
      "i" = "Run {.fun pd_auth} once interactively; the session is then
             reused by non-interactive R sessions on this machine."
    ))
  }
  cli::cli_inform(c(
    "i" = "This is a third-party application not officially supported by Proton."
  ))
  out <- pd_run_cli(c("auth", "login"), echo = TRUE)
  check_cli_status(out, "auth login")
  invisible()
}

#' @rdname pd_auth
#' @export
pd_deauth <- function() {
  pd_cli("auth", "logout", json = FALSE)
  cli::cli_inform("Signed out of Proton Drive and cleared local caches.")
  invisible()
}

#' @rdname pd_auth
#' @export
pd_has_auth <- function() {
  if (!pd_has_cli()) {
    return(FALSE)
  }
  # Listing the virtual root is local-only, but the CLI still refuses to run
  # it without a session, which makes it a cheap sign-in check.
  tryCatch(
    {
      pd_cli("filesystem", "list", "/")
      TRUE
    },
    protondrive_auth_error = function(e) FALSE
  )
}

#' Skip tests and examples that need a Proton Drive session
#'
#' Helpers for code that should only run when the CLI is installed and
#' signed in, such as package tests or vignettes.
#'
#' @return `pd_available()` returns `TRUE` or `FALSE`. `skip_if_no_pd()`
#'   is called for its side effect within testthat tests.
#' @export
#' @examples
#' pd_available()
pd_available <- function() {
  pd_has_auth()
}

#' @rdname pd_available
#' @export
skip_if_no_pd <- function() {
  if (!requireNamespace("testthat", quietly = TRUE)) {
    cli::cli_abort("{.pkg testthat} is required for {.fun skip_if_no_pd}.")
  }
  if (!pd_available()) {
    testthat::skip("Proton Drive CLI not available or not signed in")
  }
  invisible(TRUE)
}
