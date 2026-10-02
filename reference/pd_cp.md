# Copy a Proton Drive file or folder

Copies a file or folder, possibly into a different folder. This is the
analogue of `googledrive::drive_cp()`. Unlike moving, copying works
between your files and folders shared with you by other people.

## Usage

``` r
pd_cp(file, path = NULL, name = NULL, overwrite = FALSE)
```

## Arguments

- file:

  The file or folder to copy, as a path, an ID marked with
  [`as_id()`](https://hinkelman.github.io/protondrive/reference/as_id.md),
  or a one-row
  [dribble](https://hinkelman.github.io/protondrive/reference/dribble.md).

- path:

  Destination folder. Defaults to the folder `file` is in.

- name:

  Name of the copy. Defaults to `"Copy of <name>"` when copying within
  the same folder, and to the original name otherwise.

- overwrite:

  What to do if something called `name` already exists in `path`.
  `FALSE` (the default) is an error; `TRUE` moves the existing item to
  the trash first.

## Value

A one-row
[dribble](https://hinkelman.github.io/protondrive/reference/dribble.md)
for the copy, invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
pd_cp("data/mtcars.csv")
pd_cp("data/mtcars.csv", path = "archive", name = "mtcars-2026.csv")
} # }
```
