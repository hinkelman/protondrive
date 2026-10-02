# Locate the Proton Drive CLI

protondrive does not talk to the Proton Drive API directly. Encryption,
sessions, caching, and API traffic are all handled by the official
Proton Drive command-line interface (`proton-drive`), which is built on
the [Proton Drive SDK](https://github.com/ProtonDriveApps/sdk). These
functions report which executable protondrive will use and which version
it is.

The executable is found by checking, in order:

1.  The `protondrive.cli_path` option.

2.  The `PROTONDRIVE_CLI_PATH` environment variable.

3.  `proton-drive` on the `PATH`.

Download the CLI from <https://proton.me/download/drive/cli/index.html>.

## Usage

``` r
pd_cli_path()

pd_has_cli()

pd_cli_version()
```

## Value

- `pd_cli_path()`: The path to the executable, as a string.

- `pd_cli_version()`: The version text reported by the CLI, invisibly.
  It is also printed.

- `pd_has_cli()`: `TRUE` or `FALSE`.

## Examples

``` r
pd_has_cli()
#> [1] FALSE
if (pd_has_cli()) pd_cli_path()
```
