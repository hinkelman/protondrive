# CLI errors become protondrive_error conditions

    Code
      pd_cli("filesystem", "info", "/my-files/nope")
    Condition
      Error:
      ! `proton-drive filesystem info` failed.
      x Node not found: nope

# transfer failures are listed in the error

    Code
      pd_cli("filesystem", "upload", c("a.csv", "/my-files"))
    Condition
      Error:
      ! `proton-drive filesystem upload` failed.
      x 1 item(s) failed to upload
      * a.csv: ValidationError: Name conflict

