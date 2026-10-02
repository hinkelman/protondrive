# Move Proton Drive files to or from the trash

- `pd_trash()` moves files or folders to the trash. It is the analogue
  of `googledrive::drive_trash()`.

- `pd_untrash()` restores them. It is the analogue of
  `googledrive::drive_untrash()`.

- `pd_empty_trash()` permanently deletes everything in `/trash`. It is
  the analogue of `googledrive::drive_empty_trash()`. Photos in
  `/photos-trash` are not affected. Deletion happens asynchronously on
  the server.

The Proton Drive CLI identifies items in the trash by name. If the trash
holds several items with the same name, `pd_untrash()` refuses to guess
and asks you to resolve the ambiguity.

## Usage

``` r
pd_trash(file, verbose = TRUE)

pd_untrash(file, verbose = TRUE)

pd_empty_trash(verbose = TRUE)
```

## Arguments

- file:

  Files or folders, as paths, IDs marked with
  [`as_id()`](https://hinkelman.github.io/protondrive/reference/as_id.md),
  or a
  [dribble](https://hinkelman.github.io/protondrive/reference/dribble.md).
  For `pd_untrash()`, typically a dribble from `pd_ls("/trash")` or from
  `pd_trash()`.

- verbose:

  If `TRUE`, report what happened.

## Value

`pd_trash()` and `pd_untrash()` return a
[dribble](https://hinkelman.github.io/protondrive/reference/dribble.md)
of the affected items, invisibly. `pd_empty_trash()` returns `NULL`,
invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
trashed <- pd_trash("data/old.csv")
pd_ls("/trash")
pd_untrash(trashed)
pd_empty_trash()
} # }
```
