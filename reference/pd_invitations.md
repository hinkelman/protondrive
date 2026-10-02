# Manage invitations to items shared with you

- `pd_invitations()` lists pending invitations from other people, for
  both Drive and Photos.

- `pd_accept_invitation()` accepts one. The item then appears in
  `/shared-with-me`.

- `pd_reject_invitation()` declines one.

If `invited_by` is shown in parentheses, the sender's identity could not
be verified, and the invitation may have been forged. Be cautious before
accepting it.

## Usage

``` r
pd_invitations()

pd_accept_invitation(id)

pd_reject_invitation(id)
```

## Arguments

- id:

  An invitation ID, from the `id` column of `pd_invitations()`.

## Value

- `pd_invitations()`: A tibble with columns `id`, `name`, `type`,
  `role`, `invited_by`, and `invitation_time`.

- `pd_accept_invitation()`, `pd_reject_invitation()`: `NULL`, invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
inv <- pd_invitations()
pd_accept_invitation(inv$id[[1]])
} # }
```
