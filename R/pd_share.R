#' Share Proton Drive files with people
#'
#' @description
#' * `pd_share()` invites people by email, or changes the role of people who
#'   already have access. It is the analogue of [googledrive::drive_share()].
#' * `pd_unshare()` removes access for some or all people.
#' * `pd_sharing()` reports who has access and any pending invitations.
#' * `pd_leave()` gives up your access to an item someone shared with you.
#'
#' @param file A file or folder, as a path, an ID marked with [as_id()], or a
#'   one-row [dribble].
#' @param emails Character vector of email addresses.
#' @param role The role to grant: `"viewer"`, `"editor"`, or `"admin"`.
#' @param message Optional message to include in the invitation email. It is
#'   sent in clear text, not end-to-end encrypted.
#' @param include_name If `TRUE`, include the item's name in the invitation
#'   email, in clear text.
#' @param everyone For `pd_unshare()`: if `TRUE`, remove everyone's access
#'   and all pending invitations. The public link, if any, is not affected;
#'   see [pd_unshare_link()].
#'
#' @return
#' * `pd_share()`, `pd_unshare()`: A tibble of people with access, as
#'   returned by `pd_sharing()`, invisibly.
#' * `pd_sharing()`: A tibble with one row per person and columns `email`,
#'   `role`, `status` (`"member"`, `"invited"`, or `"invited (non-Proton)"`),
#'   `invited_by`, and `invitation_time`.
#' * `pd_leave()`: `NULL`, invisibly.
#' @export
#' @examples
#' \dontrun{
#' pd_share("reports", c("ana@example.com", "bo@example.com"), role = "editor")
#' pd_sharing("reports")
#' pd_unshare("reports", "bo@example.com")
#' pd_unshare("reports", everyone = TRUE)
#'
#' pd_leave("/shared-with-me/Their folder")
#' }
pd_share <- function(file, emails, role = c("viewer", "editor", "admin"),
                     message = NULL, include_name = FALSE) {
  file <- as_dribble(file)
  check_single(file, "file")
  check_emails(emails)
  role <- rlang::arg_match(role)

  info <- pd_cli(
    "sharing", "invite", pd_address(file),
    options = list(
      user = emails,
      role = role,
      message = message,
      "include-node-name" = include_name
    )
  )
  pd_inform(c(
    "v" = "Shared {.file {display_path(file)}} as {role} with:",
    bullets(emails)
  ))
  invisible(sharing_tbl(info))
}

#' @rdname pd_share
#' @export
pd_unshare <- function(file, emails = NULL, everyone = FALSE) {
  file <- as_dribble(file)
  check_single(file, "file")
  if (is.null(emails) == !isTRUE(everyone)) {
    cli::cli_abort("Supply {.arg emails} or set {.code everyone = TRUE}, not both.")
  }
  if (!is.null(emails)) {
    check_emails(emails)
  }

  info <- pd_cli(
    "sharing", "remove", pd_address(file),
    options = list(email = emails, everyone = isTRUE(everyone))
  )
  who <- if (isTRUE(everyone)) "everyone" else "{length(emails)} {?person/people}"
  pd_inform(c("v" = paste0("Removed access to {.file {display_path(file)}} for ", who, ".")))
  invisible(sharing_tbl(info))
}

#' @rdname pd_share
#' @export
pd_sharing <- function(file) {
  file <- as_dribble(file)
  check_single(file, "file")
  sharing_tbl(pd_cli("sharing", "status", pd_address(file)))
}

#' @rdname pd_share
#' @export
pd_leave <- function(file) {
  file <- as_dribble(file)
  check_single(file, "file")
  pd_cli("sharing", "leave", pd_address(file), parse = FALSE)
  pd_inform(c("v" = "Left shared item {.val {file$name}}."))
  invisible()
}

#' Share Proton Drive files by link
#'
#' @description
#' * `pd_share_link()` creates or updates a public link that lets anyone with
#'   the URL open the item. It is the analogue of
#'   [googledrive::drive_share_anyone()], but returns the URL.
#' * `pd_link()` returns the existing public link, or `NA` if there is none.
#'   It is the analogue of [googledrive::drive_link()].
#' * `pd_unshare_link()` removes the public link. People invited by email
#'   keep their access.
#'
#' @inheritParams pd_share
#' @param role `"viewer"` or `"editor"`.
#' @param password Optional password that people must enter to open the
#'   link, in addition to having the URL.
#' @param expiration Optional expiration, as a `Date`, a `POSIXct`, or an
#'   ISO 8601 string such as `"2026-12-31"`.
#'
#' @return
#' * `pd_share_link()`, `pd_link()`: The URL as a string.
#' * `pd_unshare_link()`: `NULL`, invisibly.
#' @export
#' @examples
#' \dontrun{
#' pd_share_link("reports/q3.pdf", expiration = Sys.Date() + 7)
#' pd_link("reports/q3.pdf")
#' pd_unshare_link("reports/q3.pdf")
#' }
pd_share_link <- function(file, role = c("viewer", "editor"), password = NULL,
                          expiration = NULL) {
  file <- as_dribble(file)
  check_single(file, "file")
  role <- rlang::arg_match(role)
  if (!is.null(password)) {
    check_string(password, "password")
  }

  info <- pd_cli(
    "sharing", "set-url", pd_address(file),
    options = list(
      role = role,
      password = password,
      expiration = format_expiration(expiration)
    )
  )
  url <- info$urlAccess$url %||% NA_character_
  pd_inform(c("v" = "Public link for {.file {display_path(file)}}: {.url {url}}"))
  url
}

#' @rdname pd_share_link
#' @export
pd_link <- function(file) {
  file <- as_dribble(file)
  check_single(file, "file")
  info <- pd_cli("sharing", "status", pd_address(file))
  info$urlAccess$url %||% NA_character_
}

#' @rdname pd_share_link
#' @export
pd_unshare_link <- function(file) {
  file <- as_dribble(file)
  check_single(file, "file")
  pd_cli("sharing", "remove-url", pd_address(file))
  pd_inform(c("v" = "Removed the public link for {.file {display_path(file)}}."))
  invisible()
}

# `getSharingInfo()` returns null for items that were never shared.
sharing_tbl <- function(info) {
  people <- c(
    lapply(info$members, sharing_row, status = "member"),
    lapply(info$protonInvitations, sharing_row, status = "invited"),
    lapply(info$nonProtonInvitations, sharing_row, status = "invited (non-Proton)")
  )
  if (length(people) == 0) {
    return(tibble::tibble(
      email = character(),
      role = character(),
      status = character(),
      invited_by = character(),
      invitation_time = as.POSIXct(character(), tz = "UTC")
    ))
  }
  out <- vctrs::vec_rbind(!!!people)
  out$invitation_time <- parse_time(out$invitation_time)
  out
}

sharing_row <- function(x, status) {
  tibble::tibble(
    email = x$inviteeEmail %||% NA_character_,
    role = x$role %||% NA_character_,
    status = status,
    invited_by = author_email(x$addedByEmail),
    invitation_time = x$invitationTime %||% NA_character_
  )
}

format_expiration <- function(expiration, call = rlang::caller_env()) {
  if (is.null(expiration)) {
    return(NULL)
  }
  if (inherits(expiration, "POSIXt")) {
    return(format(expiration, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"))
  }
  if (inherits(expiration, "Date")) {
    return(format(expiration, "%Y-%m-%d"))
  }
  if (is.character(expiration) && length(expiration) == 1) {
    return(expiration)
  }
  cli::cli_abort(
    "{.arg expiration} must be a Date, a POSIXct, or a single string.",
    call = call
  )
}

check_emails <- function(emails, call = rlang::caller_env()) {
  if (!is.character(emails) || length(emails) == 0 || anyNA(emails) ||
      !all(grepl("^[^@[:space:]]+@[^@[:space:]]+$", emails))) {
    cli::cli_abort(
      "{.arg emails} must be a character vector of email addresses.",
      call = call
    )
  }
  invisible(emails)
}
