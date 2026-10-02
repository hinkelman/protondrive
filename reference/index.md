# Package index

## Sign in

- [`pd_auth()`](https://hinkelman.github.io/protondrive/reference/pd_auth.md)
  [`pd_deauth()`](https://hinkelman.github.io/protondrive/reference/pd_auth.md)
  [`pd_has_auth()`](https://hinkelman.github.io/protondrive/reference/pd_auth.md)
  : Sign in to Proton Drive
- [`pd_cli_path()`](https://hinkelman.github.io/protondrive/reference/pd_cli_path.md)
  [`pd_has_cli()`](https://hinkelman.github.io/protondrive/reference/pd_cli_path.md)
  [`pd_cli_version()`](https://hinkelman.github.io/protondrive/reference/pd_cli_path.md)
  : Locate the Proton Drive CLI

## Find and inspect

- [`pd_ls()`](https://hinkelman.github.io/protondrive/reference/pd_ls.md)
  : List the contents of a Proton Drive folder
- [`pd_get()`](https://hinkelman.github.io/protondrive/reference/pd_get.md)
  : Get Proton Drive files by path or ID
- [`pd_reveal()`](https://hinkelman.github.io/protondrive/reference/pd_reveal.md)
  : Add a column of Proton Drive metadata to a dribble
- [`pd_size()`](https://hinkelman.github.io/protondrive/reference/pd_size.md)
  : Total size of Proton Drive folders

## Upload, download, read

- [`pd_upload()`](https://hinkelman.github.io/protondrive/reference/pd_upload.md)
  [`pd_put()`](https://hinkelman.github.io/protondrive/reference/pd_upload.md)
  [`pd_update()`](https://hinkelman.github.io/protondrive/reference/pd_upload.md)
  : Upload files or folders to Proton Drive
- [`pd_download()`](https://hinkelman.github.io/protondrive/reference/pd_download.md)
  : Download a file or folder from Proton Drive
- [`pd_read_string()`](https://hinkelman.github.io/protondrive/reference/pd_read_string.md)
  [`pd_read_raw()`](https://hinkelman.github.io/protondrive/reference/pd_read_string.md)
  : Read the content of a Proton Drive file

## Organise

- [`pd_mkdir()`](https://hinkelman.github.io/protondrive/reference/pd_mkdir.md)
  : Create a folder on Proton Drive
- [`pd_cp()`](https://hinkelman.github.io/protondrive/reference/pd_cp.md)
  : Copy a Proton Drive file or folder
- [`pd_mv()`](https://hinkelman.github.io/protondrive/reference/pd_mv.md)
  [`pd_rename()`](https://hinkelman.github.io/protondrive/reference/pd_mv.md)
  : Move or rename a Proton Drive file or folder
- [`pd_trash()`](https://hinkelman.github.io/protondrive/reference/pd_trash.md)
  [`pd_untrash()`](https://hinkelman.github.io/protondrive/reference/pd_trash.md)
  [`pd_empty_trash()`](https://hinkelman.github.io/protondrive/reference/pd_trash.md)
  : Move Proton Drive files to or from the trash
- [`pd_rm()`](https://hinkelman.github.io/protondrive/reference/pd_rm.md)
  : Permanently delete Proton Drive files

## Share

- [`pd_share()`](https://hinkelman.github.io/protondrive/reference/pd_share.md)
  [`pd_unshare()`](https://hinkelman.github.io/protondrive/reference/pd_share.md)
  [`pd_sharing()`](https://hinkelman.github.io/protondrive/reference/pd_share.md)
  [`pd_leave()`](https://hinkelman.github.io/protondrive/reference/pd_share.md)
  : Share Proton Drive files with people
- [`pd_share_link()`](https://hinkelman.github.io/protondrive/reference/pd_share_link.md)
  [`pd_link()`](https://hinkelman.github.io/protondrive/reference/pd_share_link.md)
  [`pd_unshare_link()`](https://hinkelman.github.io/protondrive/reference/pd_share_link.md)
  : Share Proton Drive files by link
- [`pd_invitations()`](https://hinkelman.github.io/protondrive/reference/pd_invitations.md)
  [`pd_accept_invitation()`](https://hinkelman.github.io/protondrive/reference/pd_invitations.md)
  [`pd_reject_invitation()`](https://hinkelman.github.io/protondrive/reference/pd_invitations.md)
  : Manage invitations to items shared with you

## Dribbles and IDs

- [`dribble`](https://hinkelman.github.io/protondrive/reference/dribble.md)
  : dribble object
- [`as_dribble()`](https://hinkelman.github.io/protondrive/reference/as_dribble.md)
  : Coerce to a dribble
- [`is_dribble()`](https://hinkelman.github.io/protondrive/reference/is_dribble.md)
  : Is this a dribble?
- [`as_id()`](https://hinkelman.github.io/protondrive/reference/as_id.md)
  : Mark strings as Proton Drive node IDs

## Helpers

- [`local_pd_quiet()`](https://hinkelman.github.io/protondrive/reference/local_pd_quiet.md)
  [`with_pd_quiet()`](https://hinkelman.github.io/protondrive/reference/local_pd_quiet.md)
  : Silence protondrive messages
- [`pd_available()`](https://hinkelman.github.io/protondrive/reference/pd_available.md)
  [`skip_if_no_pd()`](https://hinkelman.github.io/protondrive/reference/pd_available.md)
  : Skip tests and examples that need a Proton Drive session
