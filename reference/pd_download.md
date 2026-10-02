# Download a file or folder from Proton Drive

Downloads and decrypts a file or folder to your computer. This is the
analogue of `googledrive::drive_download()`. Proton Docs and Sheets
cannot be downloaded this way.

## Usage

``` r
pd_download(file, path = NULL, overwrite = FALSE)
```

## Arguments

- file:

  The file or folder to download, as a path, an ID marked with
  [`as_id()`](https://hinkelman.github.io/protondrive/reference/as_id.md),
  or a one-row
  [dribble](https://hinkelman.github.io/protondrive/reference/dribble.md).

- path:

  Local path to save to. Defaults to the file's name, in the working
  directory.

- overwrite:

  If `FALSE` (the default), it is an error for `path` to exist already.
  If `TRUE`, it is replaced.

## Value

A one-row
[dribble](https://hinkelman.github.io/protondrive/reference/dribble.md)
for the downloaded file, with an extra `local_path` column, invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
pd_download("data/mtcars.csv")
pd_download("data/mtcars.csv", path = tempfile(fileext = ".csv"))
pd_download("data", path = "local-copy-of-data")
} # }
```
