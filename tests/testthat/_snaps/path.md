# normalize_path() rejects unknown sections

    Code
      normalize_path("/nope/a")
    Condition
      Error:
      ! "/nope/a" is not a valid Proton Drive path.
      i Paths start with one of "/my-files", "/devices", "/shared-by-me", "/shared-with-me", "/trash", "/albums", "/photos", "/photos-shared-by-me", "/photos-shared-with-me", and "/photos-trash".
      i Relative paths are taken relative to "/my-files".

