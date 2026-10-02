# Permanently delete Proton Drive files

Permanently deletes files or folders, moving them to the trash first if
needed. **This can't be undone.** This is the analogue of
`googledrive::drive_rm()`. Use
[`pd_trash()`](https://hinkelman.github.io/protondrive/reference/pd_trash.md)
for a reversible alternative.

## Usage

``` r
pd_rm(file, verbose = TRUE)
```

## Arguments

- file:

  Files or folders, as paths, IDs marked with
  [`as_id()`](https://hinkelman.github.io/protondrive/reference/as_id.md),
  or a
  [dribble](https://hinkelman.github.io/protondrive/reference/dribble.md).
  For
  [`pd_untrash()`](https://hinkelman.github.io/protondrive/reference/pd_trash.md),
  typically a dribble from `pd_ls("/trash")` or from
  [`pd_trash()`](https://hinkelman.github.io/protondrive/reference/pd_trash.md).

- verbose:

  If `TRUE`, report what happened.

## Value

A
[dribble](https://hinkelman.github.io/protondrive/reference/dribble.md)
of the deleted items, invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
pd_rm("data/scratch.csv")
} # }
```
