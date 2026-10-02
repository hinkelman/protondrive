# dribble object

protondrive stores metadata about Proton Drive files and folders in a
dribble (a **dr**ive t**ibble**), just as googledrive does. It is a
tibble with one row per file or folder and these columns:

- `name`: the file or folder name.

- `path`: the virtual path used to reach it, such as
  `"/my-files/reports/q3.csv"`. It is `NA` when the node was looked up
  by ID or listed in `/shared-by-me`, where the CLI does not report a
  path. Paths are a snapshot: they go stale if the node is renamed or
  moved elsewhere, but protondrive addresses nodes by `id` where it can,
  so a stale path does no harm.

- `id`: the node UID, of class `pd_id`. See
  [`as_id()`](https://hinkelman.github.io/protondrive/reference/as_id.md).

- `drive_resource`: a list-column holding the full metadata the Proton
  Drive SDK returns for the node: type, media type, sizes, timestamps,
  authors, sharing state, active revision, and more. Use
  [`pd_reveal()`](https://hinkelman.github.io/protondrive/reference/pd_reveal.md)
  to pull fields out into their own columns.

A dribble survives most dplyr verbs and base subsetting. If you drop or
change one of the required columns, it reverts to a plain tibble.

## Relationship to googledrive

A protondrive dribble has the same role and columns as a googledrive
dribble, plus `path`. Its S3 class is `pd_dribble` rather than
`dribble`, so the two packages' methods never apply to each other's
objects, and the two kinds of dribble can't be mixed. Both packages
export
[`as_dribble()`](https://hinkelman.github.io/protondrive/reference/as_dribble.md)
and
[`is_dribble()`](https://hinkelman.github.io/protondrive/reference/is_dribble.md);
if you attach both, call them with a `protondrive::` or `googledrive::`
prefix.

## See also

[`as_dribble()`](https://hinkelman.github.io/protondrive/reference/as_dribble.md),
[`is_dribble()`](https://hinkelman.github.io/protondrive/reference/is_dribble.md)
