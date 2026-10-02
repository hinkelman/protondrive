# Share Proton Drive files with people

- `pd_share()` invites people by email, or changes the role of people
  who already have access. It is the analogue of
  `googledrive::drive_share()`.

- `pd_unshare()` removes access for some or all people.

- `pd_sharing()` reports who has access and any pending invitations.

- `pd_leave()` gives up your access to an item someone shared with you.

New invitees get an invitation email from Proton, whether or not they
have a Proton account. Calling `pd_share()` again for someone who
already has access or a pending invitation just changes their role; no
second email is sent. You can't share with an address that belongs to
your own Proton account.

## Usage

``` r
pd_share(
  file,
  emails,
  role = c("viewer", "editor", "admin"),
  message = NULL,
  include_name = FALSE
)

pd_unshare(file, emails = NULL, everyone = FALSE)

pd_sharing(file)

pd_leave(file)
```

## Arguments

- file:

  A file or folder, as a path, an ID marked with
  [`as_id()`](https://hinkelman.github.io/protondrive/reference/as_id.md),
  or a one-row
  [dribble](https://hinkelman.github.io/protondrive/reference/dribble.md).

- emails:

  Character vector of email addresses.

- role:

  The role to grant: `"viewer"`, `"editor"`, or `"admin"`.

- message:

  Optional message to include in the invitation email. It is sent in
  clear text, not end-to-end encrypted.

- include_name:

  If `TRUE`, include the item's name in the invitation email, in clear
  text.

- everyone:

  For `pd_unshare()`: if `TRUE`, remove everyone's access and all
  pending invitations. The public link, if any, is not affected; see
  [`pd_unshare_link()`](https://hinkelman.github.io/protondrive/reference/pd_share_link.md).

## Value

- `pd_share()`, `pd_unshare()`: A tibble of people with access, as
  returned by `pd_sharing()`, invisibly.

- `pd_sharing()`: A tibble with one row per person and columns `email`,
  `role`, `status` (`"member"`, `"invited"`, or
  `"invited (non-Proton)"`), `invited_by`, and `invitation_time`.

- `pd_leave()`: `NULL`, invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
pd_share("reports", c("ana@example.com", "bo@example.com"), role = "editor")
pd_sharing("reports")
pd_unshare("reports", "bo@example.com")
pd_unshare("reports", everyone = TRUE)

pd_leave("/shared-with-me/Their folder")
} # }
```
