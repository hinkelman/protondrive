# Skip tests and examples that need a Proton Drive session

Helpers for code that should only run when the CLI is installed and
signed in, such as package tests or vignettes.

## Usage

``` r
pd_available()

skip_if_no_pd()
```

## Value

`pd_available()` returns `TRUE` or `FALSE`. `skip_if_no_pd()` is called
for its side effect within testthat tests.

## Examples

``` r
pd_available()
#> [1] FALSE
```
