#' Manage invitations to items shared with you
#'
#' @description
#' * `pd_invitations()` lists pending invitations from other people, for both
#'   Drive and Photos.
#' * `pd_accept_invitation()` accepts one. The item then appears in
#'   `/shared-with-me`.
#' * `pd_reject_invitation()` declines one.
#'
#' If `invited_by` is shown in parentheses, the sender's identity could not be
#' verified, and the invitation may have been forged. Be cautious before
#' accepting it.
#'
#' @param id An invitation ID, from the `id` column of `pd_invitations()`.
#'
#' @return
#' * `pd_invitations()`: A tibble with columns `id`, `name`, `type`, `role`,
#'   `invited_by`, and `invitation_time`.
#' * `pd_accept_invitation()`, `pd_reject_invitation()`: `NULL`, invisibly.
#' @export
#' @examples
#' \dontrun{
#' inv <- pd_invitations()
#' pd_accept_invitation(inv$id[[1]])
#' }
pd_invitations <- function() {
  invitations <- pd_cli("invitation", "list")
  if (length(invitations) == 0) {
    return(tibble::tibble(
      id = character(),
      name = character(),
      type = character(),
      role = character(),
      invited_by = character(),
      invitation_time = as.POSIXct(character(), tz = "UTC")
    ))
  }
  tibble::tibble(
    id = vapply(invitations, function(x) x$uid, character(1)),
    name = vapply(invitations, function(x) node_name(x$node), character(1)),
    type = vapply(invitations, function(x) x$node$type %||% NA_character_, character(1)),
    role = vapply(invitations, function(x) x$role %||% NA_character_, character(1)),
    invited_by = vapply(invitations, function(x) author_email(x$addedByEmail), character(1)),
    invitation_time = parse_time(vapply(
      invitations,
      function(x) x$invitationTime %||% NA_character_,
      character(1)
    ))
  )
}

#' @rdname pd_invitations
#' @export
pd_accept_invitation <- function(id) {
  check_string(id, "id")
  pd_cli("invitation", "accept", id, parse = FALSE)
  pd_inform(c("v" = "Accepted invitation. Find the item in {.file /shared-with-me}."))
  invisible()
}

#' @rdname pd_invitations
#' @export
pd_reject_invitation <- function(id) {
  check_string(id, "id")
  pd_cli("invitation", "reject", id, parse = FALSE)
  pd_inform(c("v" = "Rejected invitation."))
  invisible()
}
