# Get Proton Drive files by path or ID

Retrieves metadata for files or folders, given their paths or IDs, and
returns it as a
[dribble](https://hinkelman.github.io/protondrive/reference/dribble.md).
This is the analogue of `googledrive::drive_get()`.

Paths are virtual and always use forward slashes. Your own files live
under `/my-files`, which is also where relative paths and `~` point.
Other top-level sections are `/devices`, `/shared-with-me`,
`/shared-by-me`, `/trash`, `/photos`, and `/albums`. A literal `/` in a
file name is written as `\/`.

## Usage

``` r
pd_get(path = NULL, id = NULL)
```

## Arguments

- path:

  Character vector of paths, such as `"reports/q3.csv"` or
  `"/shared-with-me/Team/plan.docx"`. A character vector marked with
  [`as_id()`](https://hinkelman.github.io/protondrive/reference/as_id.md)
  is treated as IDs.

- id:

  Character vector of node IDs. Supply `path` or `id`, not both.

## Value

A
[dribble](https://hinkelman.github.io/protondrive/reference/dribble.md)
with one row per input.

## Examples

``` r
if (FALSE) { # \dontrun{
pd_get("reports/q3.csv")
pd_get(c("~/data", "/shared-with-me/Team"))
pd_get(id = "vol...~node...")
} # }
```
