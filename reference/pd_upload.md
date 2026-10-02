# Upload files or folders to Proton Drive

- `pd_upload()` uploads a local file or folder. It is the analogue of
  `googledrive::drive_upload()`.

- `pd_put()` uploads a file, or adds a new revision if a file of that
  name already exists. It is the analogue of `googledrive::drive_put()`.

- `pd_update()` uploads new content for an existing Proton Drive file,
  as a new revision. It is the analogue of
  `googledrive::drive_update()`.

New revisions keep the file's ID, sharing settings, and version history.
The Proton Drive CLI skips uploads whose content is identical to the
existing file.

## Usage

``` r
pd_upload(
  media,
  path = NULL,
  name = NULL,
  overwrite = FALSE,
  thumbnails = TRUE
)

pd_put(media, path = NULL, name = NULL, thumbnails = TRUE)

pd_update(file, media, thumbnails = TRUE)
```

## Arguments

- media:

  Path to a local file or folder.

- path:

  Destination folder, given as a path, an ID marked with
  [`as_id()`](https://hinkelman.github.io/protondrive/reference/as_id.md),
  or a one-row
  [dribble](https://hinkelman.github.io/protondrive/reference/dribble.md).
  Defaults to `/my-files`.

- name:

  Name for the uploaded file or folder. Defaults to the local name.

- overwrite:

  What to do if something called `name` already exists in `path`. If
  `FALSE` (the default) the upload fails. If `TRUE`, a file is uploaded
  as a new revision of the existing file and a folder's contents are
  merged into the existing folder.

- thumbnails:

  If `TRUE`, the CLI generates preview thumbnails for images. Set to
  `FALSE` if thumbnail generation fails on your system.

- file:

  The Proton Drive file to update, as a path, an ID marked with
  [`as_id()`](https://hinkelman.github.io/protondrive/reference/as_id.md),
  or a one-row
  [dribble](https://hinkelman.github.io/protondrive/reference/dribble.md).

## Value

A one-row
[dribble](https://hinkelman.github.io/protondrive/reference/dribble.md)
for the uploaded file or folder, invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
write.csv(mtcars, "mtcars.csv")
pd_upload("mtcars.csv", path = "data")
pd_put("mtcars.csv", path = "data")

f <- pd_get("data/mtcars.csv")
pd_update(f, "mtcars.csv")
} # }
```
