# Total size of Proton Drive folders

Calculates the total size of each folder and how many items it holds,
counting all descendants, including trashed ones. The calculation runs
on the server; nothing is downloaded.

This needs a Proton Drive CLI with the `filesystem size` command. CLI
0.8.0 does not have it; it is in development in the Proton Drive SDK
repository. Older CLIs give an error of class `protondrive_unsupported`.

## Usage

``` r
pd_size(file)
```

## Arguments

- file:

  Folders, as paths, IDs marked with
  [`as_id()`](https://hinkelman.github.io/protondrive/reference/as_id.md),
  or a
  [dribble](https://hinkelman.github.io/protondrive/reference/dribble.md).

## Value

A tibble with columns `name`, `path`, `size` (bytes), and `n_items`.

## Examples

``` r
if (FALSE) { # \dontrun{
pd_size("~")
pd_ls(type = "folder") |> pd_size()
} # }
```
