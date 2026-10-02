# Create a folder on Proton Drive

Creates a new folder. This is the analogue of
`googledrive::drive_mkdir()`.

## Usage

``` r
pd_mkdir(name, path = NULL, overwrite = FALSE)
```

## Arguments

- name:

  Name of the new folder. It may include a path, such as
  `"reports/2026"`, in which case `path` must not be given and the
  parent (here `reports`) must already exist.

- path:

  Parent folder, given as a path, an ID marked with
  [`as_id()`](https://hinkelman.github.io/protondrive/reference/as_id.md),
  or a one-row
  [dribble](https://hinkelman.github.io/protondrive/reference/dribble.md).
  Defaults to `/my-files`.

- overwrite:

  What to do if a file or folder called `name` already exists in `path`.
  Proton Drive never allows two items with the same name in one folder,
  so `FALSE` (the default) is an error, while `TRUE` moves the existing
  item to the trash first.

## Value

A one-row
[dribble](https://hinkelman.github.io/protondrive/reference/dribble.md)
for the new folder, invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
pd_mkdir("analysis")
pd_mkdir("figures", path = "analysis")
pd_mkdir("analysis/tables")
} # }
```
