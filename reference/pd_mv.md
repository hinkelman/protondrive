# Move or rename a Proton Drive file or folder

- `pd_mv()` moves a file or folder into a different folder, and can
  rename it at the same time. It is the analogue of
  `googledrive::drive_mv()`.

- `pd_rename()` renames a file or folder in place. It is the analogue of
  `googledrive::drive_rename()`.

Items can only be moved within the same owner's drive. To move between
your files and a folder someone shared with you, use
[`pd_cp()`](https://hinkelman.github.io/protondrive/reference/pd_cp.md)
and then
[`pd_trash()`](https://hinkelman.github.io/protondrive/reference/pd_trash.md).

## Usage

``` r
pd_mv(file, path = NULL, name = NULL, overwrite = FALSE)

pd_rename(file, name, overwrite = FALSE, verbose = TRUE)
```

## Arguments

- file:

  The file or folder to move or rename, as a path, an ID marked with
  [`as_id()`](https://hinkelman.github.io/protondrive/reference/as_id.md),
  or a one-row
  [dribble](https://hinkelman.github.io/protondrive/reference/dribble.md).

- path:

  Destination folder. If `NULL`, the item stays where it is.

- name:

  New name. If `NULL`, the name is unchanged.

- overwrite:

  What to do if something called `name` already exists in `path`.
  `FALSE` (the default) is an error; `TRUE` moves the existing item to
  the trash first.

- verbose:

  If `TRUE`, report what happened.

## Value

A one-row
[dribble](https://hinkelman.github.io/protondrive/reference/dribble.md)
for the item, with updated metadata, invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
pd_mv("data/mtcars.csv", path = "archive")
pd_mv("data/mtcars.csv", path = "archive", name = "old-mtcars.csv")
pd_rename("data/mtcars.csv", "cars.csv")
} # }
```
