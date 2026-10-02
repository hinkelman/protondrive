# Silence protondrive messages

protondrive reports what it did, such as "Uploaded x to y". To silence
these messages, set the option `protondrive_quiet = TRUE`, or use these
helpers, which mirror `googledrive::local_drive_quiet()` and
`googledrive::with_drive_quiet()`. Errors and warnings are never
silenced.

## Usage

``` r
local_pd_quiet(env = parent.frame())

with_pd_quiet(code)
```

## Arguments

- env:

  The environment whose exit ends the quiet period.

- code:

  Code to run quietly.

## Value

`with_pd_quiet()` returns the result of `code`.

## Examples

``` r
if (FALSE) { # \dontrun{
with_pd_quiet(pd_upload("mtcars.csv"))

f <- function() {
  local_pd_quiet()
  pd_mkdir("scratch")
}
} # }
```
