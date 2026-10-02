# Share Proton Drive files by link

- `pd_share_link()` creates or updates a public link that lets anyone
  with the URL open the item. It is the analogue of
  `googledrive::drive_share_anyone()`, but returns the URL.

- `pd_link()` returns the existing public link, or `NA` if there is
  none. It is the analogue of `googledrive::drive_link()`.

- `pd_unshare_link()` removes the public link. People invited by email
  keep their access.

## Usage

``` r
pd_share_link(
  file,
  role = c("viewer", "editor"),
  password = NULL,
  expiration = NULL
)

pd_link(file)

pd_unshare_link(file)
```

## Arguments

- file:

  A file or folder, as a path, an ID marked with
  [`as_id()`](https://hinkelman.github.io/protondrive/reference/as_id.md),
  or a one-row
  [dribble](https://hinkelman.github.io/protondrive/reference/dribble.md).

- role:

  `"viewer"` or `"editor"`.

- password:

  Optional password that people must enter to open the link, in addition
  to having the URL.

- expiration:

  Optional expiration, as a `Date`, a `POSIXct`, or an ISO 8601 string
  such as `"2026-12-31"` or `"2026-12-31T17:00:00Z"`. A date without a
  time means the link works through the end of that day (23:59:59) in
  your local time zone.

## Value

- `pd_share_link()`, `pd_link()`: The URL as a string.

- `pd_unshare_link()`: `NULL`, invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
pd_share_link("reports/q3.pdf", expiration = Sys.Date() + 7)
pd_link("reports/q3.pdf")
pd_unshare_link("reports/q3.pdf")
} # }
```
