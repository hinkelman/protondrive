# protondrive

protondrive lets you work with files on [Proton
Drive](https://proton.me/drive) from R. Its interface is modelled on
[googledrive](https://googledrive.tidyverse.org): if you know
`drive_ls()`, `drive_upload()`, and the dribble, you already know
[`pd_ls()`](https://hinkelman.github.io/protondrive/reference/pd_ls.md),
[`pd_upload()`](https://hinkelman.github.io/protondrive/reference/pd_upload.md),
and protondrive’s dribble.

> **This is a third-party application not officially supported by
> Proton.**

## How it works

Proton Drive is end-to-end encrypted, so a client has to encrypt,
decrypt, and sign everything locally. Proton publishes the [Proton Drive
SDK](https://github.com/ProtonDriveApps/sdk) for this. However, the SDK
does not handle sign-in or session management. Proton’s official
**Proton Drive CLI** (`proton-drive`), built on the SDK, adds those
pieces.

protondrive drives that CLI. Each function runs one CLI command with
`--json` and turns the result into a tibble. So:

- Your password never passes through R. You sign in through Proton’s own
  web page, and the CLI keeps the session in your operating system’s
  secret store.
- Encryption, caching, rate limiting, and the `x-pm-appversion` header
  are handled by Proton’s own code. protondrive itself makes no network
  requests.

## Installation

1.  Install the Proton Drive CLI from
    <https://proton.me/download/drive/cli/index.html> and put
    `proton-drive` on your `PATH`. If it lives somewhere else, set
    `PROTONDRIVE_CLI_PATH` (in `.Renviron`) or
    `options(protondrive.cli_path = ...)` to its location.

2.  Install protondrive from GitHub:

    ``` r

    # install.packages("pak")
    pak::pak("hinkelman/protondrive")
    ```

3.  Sign in once per machine. A browser window opens. The session then
    persists across R sessions:

    ``` r

    library(protondrive)
    pd_auth()
    ```

## Usage

``` r

library(protondrive)

# What's in My files?
pd_ls()

# Paths are relative to /my-files unless they start with a section.
pd_ls("reports", pattern = "\\.csv$")
pd_ls("/shared-with-me")

# Upload, then read back.
write.csv(mtcars, "mtcars.csv", row.names = FALSE)
pd_mkdir("data")
f <- pd_upload("mtcars.csv", path = "data")
head(read.csv(text = pd_read_string(f)))

# A dribble holds the full metadata; reveal what you need.
pd_ls("data") |> pd_reveal(c("size", "modified_time"))

# Update the file in place, as a new revision.
pd_put("mtcars.csv", path = "data")

# Organise.
pd_cp(f, name = "mtcars-backup.csv")
pd_mv(f, path = "archive")

# Share.
pd_share(f, "colleague@proton.me", role = "editor")
pd_share_link(f, expiration = Sys.Date() + 7)

# Clean up.
pd_trash(f)
```

## Coming from googledrive

| googledrive | protondrive | notes |
|----|----|----|
| `drive_auth()`, `drive_deauth()` | [`pd_auth()`](https://hinkelman.github.io/protondrive/reference/pd_auth.md), [`pd_deauth()`](https://hinkelman.github.io/protondrive/reference/pd_auth.md) | browser sign-in through the CLI |
| `drive_has_token()` | [`pd_has_auth()`](https://hinkelman.github.io/protondrive/reference/pd_auth.md) |  |
| `dribble`, [`as_dribble()`](https://hinkelman.github.io/protondrive/reference/as_dribble.md), [`is_dribble()`](https://hinkelman.github.io/protondrive/reference/is_dribble.md) | `dribble`, [`as_dribble()`](https://hinkelman.github.io/protondrive/reference/as_dribble.md), [`is_dribble()`](https://hinkelman.github.io/protondrive/reference/is_dribble.md) | adds a `path` column; class `pd_dribble` |
| [`as_id()`](https://hinkelman.github.io/protondrive/reference/as_id.md) | [`as_id()`](https://hinkelman.github.io/protondrive/reference/as_id.md) |  |
| `drive_get()` | [`pd_get()`](https://hinkelman.github.io/protondrive/reference/pd_get.md) |  |
| `drive_ls()` | [`pd_ls()`](https://hinkelman.github.io/protondrive/reference/pd_ls.md) |  |
| `drive_reveal()` | [`pd_reveal()`](https://hinkelman.github.io/protondrive/reference/pd_reveal.md) |  |
| `drive_mkdir()` | [`pd_mkdir()`](https://hinkelman.github.io/protondrive/reference/pd_mkdir.md) |  |
| `drive_upload()`, `drive_put()`, `drive_update()` | [`pd_upload()`](https://hinkelman.github.io/protondrive/reference/pd_upload.md), [`pd_put()`](https://hinkelman.github.io/protondrive/reference/pd_upload.md), [`pd_update()`](https://hinkelman.github.io/protondrive/reference/pd_upload.md) | updates add revisions |
| `drive_download()` | [`pd_download()`](https://hinkelman.github.io/protondrive/reference/pd_download.md) | also downloads folders |
| `drive_read_string()`, `drive_read_raw()` | [`pd_read_string()`](https://hinkelman.github.io/protondrive/reference/pd_read_string.md), [`pd_read_raw()`](https://hinkelman.github.io/protondrive/reference/pd_read_string.md) |  |
| `drive_cp()`, `drive_mv()`, `drive_rename()` | [`pd_cp()`](https://hinkelman.github.io/protondrive/reference/pd_cp.md), [`pd_mv()`](https://hinkelman.github.io/protondrive/reference/pd_mv.md), [`pd_rename()`](https://hinkelman.github.io/protondrive/reference/pd_mv.md) |  |
| `drive_trash()`, `drive_untrash()`, `drive_empty_trash()` | [`pd_trash()`](https://hinkelman.github.io/protondrive/reference/pd_trash.md), [`pd_untrash()`](https://hinkelman.github.io/protondrive/reference/pd_trash.md), [`pd_empty_trash()`](https://hinkelman.github.io/protondrive/reference/pd_trash.md) |  |
| `drive_rm()` | [`pd_rm()`](https://hinkelman.github.io/protondrive/reference/pd_rm.md) | permanent |
| `drive_share()` | [`pd_share()`](https://hinkelman.github.io/protondrive/reference/pd_share.md), [`pd_unshare()`](https://hinkelman.github.io/protondrive/reference/pd_share.md), [`pd_sharing()`](https://hinkelman.github.io/protondrive/reference/pd_share.md) |  |
| `drive_share_anyone()`, `drive_link()` | [`pd_share_link()`](https://hinkelman.github.io/protondrive/reference/pd_share_link.md), [`pd_link()`](https://hinkelman.github.io/protondrive/reference/pd_share_link.md) | password and expiry supported |
| `local_drive_quiet()`, `with_drive_quiet()` | [`local_pd_quiet()`](https://hinkelman.github.io/protondrive/reference/local_pd_quiet.md), [`with_pd_quiet()`](https://hinkelman.github.io/protondrive/reference/local_pd_quiet.md) |  |
| — | [`pd_size()`](https://hinkelman.github.io/protondrive/reference/pd_size.md), [`pd_invitations()`](https://hinkelman.github.io/protondrive/reference/pd_invitations.md), [`pd_leave()`](https://hinkelman.github.io/protondrive/reference/pd_share.md) | Proton-specific |

Not available: `drive_find()` and full-text search, because the SDK does
not offer search yet. Also not available: `drive_browse()`, and
Google-specific features such as shared drives and file conversion.

## Differences to keep in mind

- **Names are unique within a folder.** Proton Drive rejects duplicates,
  so functions that create items take an `overwrite` argument. With
  `overwrite = TRUE`, an existing file gets a new revision, or the
  existing item is moved to the trash, depending on the function.
- **IDs over paths.** A dribble records both the path and the ID of each
  item. protondrive addresses items by ID wherever the CLI allows, so a
  dribble keeps working after its items are renamed or moved.
- **The trash is addressed by name.** The CLI identifies trashed items
  by name.
  [`pd_untrash()`](https://hinkelman.github.io/protondrive/reference/pd_trash.md)
  and
  [`pd_rm()`](https://hinkelman.github.io/protondrive/reference/pd_rm.md)
  check that the name is unambiguous and refers to the item you meant
  before acting.
- **Be gentle with the API.** Proton asks third-party clients to avoid
  frequent recursive traversals. Use `pd_ls(recursive = TRUE)` sparingly
  on large trees.

## Status

Both the Proton Drive SDK and the CLI are pre-release, and Proton plans
a cryptographic migration around the end of 2026. Keep the CLI up to
date
([`pd_cli_version()`](https://hinkelman.github.io/protondrive/reference/pd_cli_path.md)
tells you whether a newer one exists). protondrive’s interface may also
change.
