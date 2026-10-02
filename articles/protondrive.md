# Getting started with protondrive

*This is a third-party package that is not officially supported by
Proton.*

protondrive manages files on Proton Drive from R. It works by running
the official Proton Drive CLI, which is built on the [Proton Drive
SDK](https://github.com/ProtonDriveApps/sdk) and does all the encryption
and API work. The code in this vignette is not run when the package is
built, because it needs a signed-in Proton account.

## Setup

Install the CLI from <https://proton.me/download/drive/cli/index.html>,
then check that protondrive can find it:

``` r

library(protondrive)
pd_has_cli()
pd_cli_version()
```

Sign in. A browser window opens, and once you finish signing in the
session is stored in your operating system’s secret store. You only need
to sign in once per machine:

``` r

pd_auth()
pd_has_auth()
#> [1] TRUE
```

## Paths

Proton Drive paths are virtual and always use `/`. The first part of a
path is a section:

| path                 | contents                                 |
|----------------------|------------------------------------------|
| `/my-files`          | your own files and folders               |
| `/devices`           | computers backed up with the desktop app |
| `/shared-with-me`    | items others have shared with you        |
| `/shared-by-me`      | items you have shared                    |
| `/trash`             | trashed items                            |
| `/photos`, `/albums` | Proton Photos                            |

A path that doesn’t start with `/` is relative to `/my-files`, and `~`
means `/my-files`, so these are equivalent:

``` r

pd_ls("reports/2026")
pd_ls("~/reports/2026")
pd_ls("/my-files/reports/2026")
```

If a name itself contains a `/`, write it as `\/`. In an R string that
is `"a\\/b"`.

## The dribble

As in googledrive, a dribble (“drive tibble”) is a tibble with one row
per file or folder:

``` r

x <- pd_ls("reports")
x
#> # A dribble: 3 × 4
#>   name     path                       id                       drive_resource
#>   <chr>    <chr>                      <pd_id>                  <list>
#> 1 2025     /my-files/reports/2025     xKq3…H9w~Rt7a…kL0=       <named list>
#> 2 2026     /my-files/reports/2026     xKq3…H9w~p2Vd…Qe4=       <named list>
#> 3 q3.csv   /my-files/reports/q3.csv   xKq3…H9w~9sLm…Zb1=       <named list>
```

`drive_resource` holds everything the SDK knows about each item.
[`pd_reveal()`](https://hinkelman.github.io/protondrive/reference/pd_reveal.md)
pulls fields into columns:

``` r

x |> pd_reveal(c("type", "size", "modified_time", "shared"))
```

Every function that takes a `file` or `path` argument accepts a path, an
ID wrapped in
[`as_id()`](https://hinkelman.github.io/protondrive/reference/as_id.md),
or a dribble. Dribbles work well with dplyr:

``` r

library(dplyr)

pd_ls("reports", recursive = TRUE) |>
  pd_reveal("modified_time") |>
  filter(modified_time < as.POSIXct("2025-01-01")) |>
  pd_trash()
```

## Uploading and downloading

``` r

write.csv(mtcars, "mtcars.csv", row.names = FALSE)

pd_mkdir("data")
f <- pd_upload("mtcars.csv", path = "data")
```

Proton Drive never allows two items with the same name in one folder. By
default
[`pd_upload()`](https://hinkelman.github.io/protondrive/reference/pd_upload.md)
fails if the name is taken.
[`pd_put()`](https://hinkelman.github.io/protondrive/reference/pd_upload.md)
(or `overwrite = TRUE`) uploads a new **revision** of the existing file
instead, which keeps its ID, sharing settings, and version history. The
CLI skips the upload entirely if the content is unchanged.

``` r

pd_put("mtcars.csv", path = "data")
pd_update(f, "mtcars.csv")
```

Download to disk, or read straight into R:

``` r

pd_download(f, path = "mtcars-copy.csv")
read.csv(text = pd_read_string(f))
```

Downloads are decrypted and verified by the CLI. Proton Docs and Sheets
cannot be downloaded this way.

## Organising

``` r

pd_cp(f)                                 # "Copy of mtcars.csv", same folder
pd_cp(f, path = "archive", name = "mtcars-2026.csv")
pd_rename(f, "cars.csv")
pd_mv(f, path = "archive")
pd_size("archive")
```

## Trash

``` r

trashed <- pd_trash(f)
pd_ls("/trash")
pd_untrash(trashed)

pd_rm(f)            # permanent: trashes, then deletes
pd_empty_trash()    # permanent: everything in /trash
```

The CLI identifies trashed items by name. If two trashed items share a
name,
[`pd_untrash()`](https://hinkelman.github.io/protondrive/reference/pd_trash.md)
and
[`pd_rm()`](https://hinkelman.github.io/protondrive/reference/pd_rm.md)
refuse to guess.

## Sharing

``` r

pd_share("reports", c("ana@proton.me", "bo@example.com"), role = "editor")
pd_sharing("reports")
pd_unshare("reports", "bo@example.com")

url <- pd_share_link("reports/q3.csv", password = "s3cret", expiration = Sys.Date() + 7)
pd_link("reports/q3.csv")
pd_unshare_link("reports/q3.csv")
```

Invitations from others:

``` r

inv <- pd_invitations()
pd_accept_invitation(inv$id[[1]])
pd_ls("/shared-with-me")
```

## Using protondrive in scripts and tests

Sign in interactively once. After that, non-interactive R sessions on
the same machine reuse the session. To silence status messages, use
[`local_pd_quiet()`](https://hinkelman.github.io/protondrive/reference/local_pd_quiet.md)
or
[`with_pd_quiet()`](https://hinkelman.github.io/protondrive/reference/local_pd_quiet.md).
In package tests,
[`skip_if_no_pd()`](https://hinkelman.github.io/protondrive/reference/pd_available.md)
skips when the CLI is missing or not signed in.
