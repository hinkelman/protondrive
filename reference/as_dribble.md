# Coerce to a dribble

Converts various inputs into a
[dribble](https://hinkelman.github.io/protondrive/reference/dribble.md).
This is how every protondrive function interprets its `file` and `path`
arguments:

- A dribble is returned as is.

- A character vector is treated as paths and looked up with
  [`pd_get()`](https://hinkelman.github.io/protondrive/reference/pd_get.md).

- A character vector marked with
  [`as_id()`](https://hinkelman.github.io/protondrive/reference/as_id.md)
  is looked up by ID.

- A data frame with the columns of a dribble is validated and converted.

## Usage

``` r
as_dribble(x, ..., call = rlang::caller_env())
```

## Arguments

- x:

  An object to coerce.

- ...:

  Not used.

- call:

  The execution environment of a currently running function, used in
  error messages.

## Value

A dribble.

## Examples

``` r
if (FALSE) { # \dontrun{
as_dribble("reports/q3.csv")
as_dribble(as_id("vol...~node..."))
} # }
```
