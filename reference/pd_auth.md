# Sign in to Proton Drive

`pd_auth()` signs you in to Proton Drive. It opens a browser window
where you sign in with your Proton account, and waits until you finish.
You can also open the printed URL on another device.

Your password never passes through R. The session is created and stored
by the Proton Drive CLI, in your operating system's secret store
(Keychain, Windows Credential Manager, or libsecret), and persists
across R sessions. You usually only need to sign in once per machine.

*This is a third-party application not officially supported by Proton.*

## Usage

``` r
pd_auth(force = FALSE)

pd_deauth()

pd_has_auth()
```

## Arguments

- force:

  If `TRUE`, sign in again even if a session already exists.

## Value

- `pd_auth()`, `pd_deauth()`: `NULL`, invisibly.

- `pd_has_auth()`: `TRUE` if a usable session exists, `FALSE` otherwise.

## Details

Where the CLI stores the session is controlled by the
`PROTON_DRIVE_CREDENTIALS_STORE` environment variable (`keychain`, the
default, or `pass`). See the CLI's documentation for details.

## Examples

``` r
if (FALSE) { # \dontrun{
pd_auth()
pd_has_auth()
pd_deauth()
} # }
```
