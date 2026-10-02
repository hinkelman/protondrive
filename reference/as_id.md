# Mark strings as Proton Drive node IDs

Every file and folder on Proton Drive has a unique ID (a "node UID") of
the form `<volume id>~<node id>`. `as_id()` marks a character vector as
IDs, so that functions like
[`pd_get()`](https://hinkelman.github.io/protondrive/reference/pd_get.md)
treat them as IDs rather than paths. It is the analogue of
`googledrive::as_id()`.

Unlike paths, IDs keep working after a file is renamed or moved.

## Usage

``` r
as_id(x, ...)
```

## Arguments

- x:

  A character vector of IDs, a
  [dribble](https://hinkelman.github.io/protondrive/reference/dribble.md),
  or a data frame with an `id` column.

- ...:

  Not used.

## Value

A character vector with class `pd_id`.

## Examples

``` r
as_id("vol0000000000000000001~node00000000000000001")
#> <pd_id[1]>
#> [1] vol0000000000000000001~node00000000000000001

if (FALSE) { # \dontrun{
as_id(pd_ls())
} # }
```
