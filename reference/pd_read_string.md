# Read the content of a Proton Drive file

Downloads a file and returns its content directly, without leaving a
copy on disk. These are the analogues of
`googledrive::drive_read_string()` and `googledrive::drive_read_raw()`.

## Usage

``` r
pd_read_string(file, encoding = "UTF-8")

pd_read_raw(file)
```

## Arguments

- file:

  The file or folder to download, as a path, an ID marked with
  [`as_id()`](https://hinkelman.github.io/protondrive/reference/as_id.md),
  or a one-row
  [dribble](https://hinkelman.github.io/protondrive/reference/dribble.md).

- encoding:

  Encoding of the file's text, passed to
  [`iconv()`](https://rdrr.io/r/base/iconv.html).

## Value

- `pd_read_string()`: a single string.

- `pd_read_raw()`: a raw vector.

## Examples

``` r
if (FALSE) { # \dontrun{
pd_read_string("data/mtcars.csv") |> read.csv(text = _)
pd_read_raw("images/logo.png")
} # }
```
