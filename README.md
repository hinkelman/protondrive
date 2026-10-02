# protondrive

<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

protondrive lets you work with files on [Proton Drive](https://proton.me/drive) from R. Its interface is modelled on [googledrive](https://googledrive.tidyverse.org): if you know `drive_ls()`, `drive_upload()`, and the dribble, you already know `pd_ls()`, `pd_upload()`, and protondrive's dribble.

> **This is a third-party application not officially supported by Proton.**

## How it works

Proton Drive is end-to-end encrypted, so a client has to encrypt, decrypt, and sign everything locally. Proton publishes the [Proton Drive SDK](https://github.com/ProtonDriveApps/sdk) for this. However, the SDK does not handle sign-in or session management. Proton's official **Proton Drive CLI** (`proton-drive`), built on the SDK, adds those pieces.

protondrive drives that CLI. Each function runs one CLI command with `--json` and turns the result into a tibble. So:

- Your password never passes through R. You sign in through Proton's own web page, and the CLI keeps the session in your operating system's secret store.
- Encryption, caching, rate limiting, and the `x-pm-appversion` header are handled by Proton's own code. protondrive itself makes no network requests.

## Installation

1. Install the Proton Drive CLI from <https://proton.me/download/drive/cli/index.html> and put `proton-drive` on your `PATH`. If it lives somewhere else, set `PROTONDRIVE_CLI_PATH` (in `.Renviron`) or `options(protondrive.cli_path = ...)` to its location.

2. Install protondrive from GitHub:

   ```r
   # install.packages("pak")
   pak::pak("hinkelman/protondrive")
   ```

3. Sign in once per machine. A browser window opens. The session then persists across R sessions:

   ```r
   library(protondrive)
   pd_auth()
   ```

## Usage

```r
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
|---|---|---|
| `drive_auth()`, `drive_deauth()` | `pd_auth()`, `pd_deauth()` | browser sign-in through the CLI |
| `drive_has_token()` | `pd_has_auth()` | |
| `dribble`, `as_dribble()`, `is_dribble()` | `dribble`, `as_dribble()`, `is_dribble()` | adds a `path` column; class `pd_dribble` |
| `as_id()` | `as_id()` | |
| `drive_get()` | `pd_get()` | |
| `drive_ls()` | `pd_ls()` | |
| `drive_reveal()` | `pd_reveal()` | |
| `drive_mkdir()` | `pd_mkdir()` | |
| `drive_upload()`, `drive_put()`, `drive_update()` | `pd_upload()`, `pd_put()`, `pd_update()` | updates add revisions |
| `drive_download()` | `pd_download()` | also downloads folders |
| `drive_read_string()`, `drive_read_raw()` | `pd_read_string()`, `pd_read_raw()` | |
| `drive_cp()`, `drive_mv()`, `drive_rename()` | `pd_cp()`, `pd_mv()`, `pd_rename()` | |
| `drive_trash()`, `drive_untrash()`, `drive_empty_trash()` | `pd_trash()`, `pd_untrash()`, `pd_empty_trash()` | |
| `drive_rm()` | `pd_rm()` | permanent |
| `drive_share()` | `pd_share()`, `pd_unshare()`, `pd_sharing()` | |
| `drive_share_anyone()`, `drive_link()` | `pd_share_link()`, `pd_link()` | password and expiry supported |
| `local_drive_quiet()`, `with_drive_quiet()` | `local_pd_quiet()`, `with_pd_quiet()` | |
| — | `pd_size()`, `pd_invitations()`, `pd_leave()` | Proton-specific |

Not available: `drive_find()` and full-text search, because the SDK does not offer search yet. Also not available: `drive_browse()`, and Google-specific features such as shared drives and file conversion.

## Differences to keep in mind

- **Names are unique within a folder.** Proton Drive rejects duplicates, so functions that create items take an `overwrite` argument. With `overwrite = TRUE`, an existing file gets a new revision, or the existing item is moved to the trash, depending on the function.
- **IDs over paths.** A dribble records both the path and the ID of each item. protondrive addresses items by ID wherever the CLI allows, so a dribble keeps working after its items are renamed or moved.
- **The trash is addressed by name.** The CLI identifies trashed items by name. `pd_untrash()` and `pd_rm()` check that the name is unambiguous and refers to the item you meant before acting.
- **Be gentle with the API.** Proton asks third-party clients to avoid frequent recursive traversals. Use `pd_ls(recursive = TRUE)` sparingly on large trees.

## Status

Both the Proton Drive SDK and the CLI are pre-release, and Proton plans a cryptographic migration around the end of 2026. Keep the CLI up to date (`pd_cli_version()` tells you whether a newer one exists). protondrive's interface may also change.
