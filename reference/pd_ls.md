# List the contents of a Proton Drive folder

Lists the files and folders inside a folder, as a
[dribble](https://hinkelman.github.io/protondrive/reference/dribble.md).
This is the analogue of `googledrive::drive_ls()`.

Some paths are special:

- `"/"` lists the top-level sections.

- `"/devices"` lists your computers backed up to Proton Drive.

- `"/shared-with-me"` and `"/shared-by-me"` list shared items.

- `"/trash"` lists trashed items.

## Usage

``` r
pd_ls(path = NULL, pattern = NULL, type = NULL, recursive = FALSE, ...)
```

## Arguments

- path:

  A folder, given as a path, an ID marked with
  [`as_id()`](https://hinkelman.github.io/protondrive/reference/as_id.md),
  or a one-row
  [dribble](https://hinkelman.github.io/protondrive/reference/dribble.md).
  Defaults to `/my-files`.

- pattern:

  A regular expression. Only names that match are returned.

- type:

  Only return nodes of this type, such as `"file"` or `"folder"`.

- recursive:

  If `TRUE`, also list the contents of sub-folders. Proton asks that
  third-party clients avoid frequent recursive traversals, so use this
  sparingly on large trees.

- ...:

  Not used.

## Value

A
[dribble](https://hinkelman.github.io/protondrive/reference/dribble.md).

## Examples

``` r
if (FALSE) { # \dontrun{
pd_ls()
pd_ls("reports", pattern = "\\.csv$")
pd_ls("/shared-with-me")
pd_ls("/trash")
} # }
```
