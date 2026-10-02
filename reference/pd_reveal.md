# Add a column of Proton Drive metadata to a dribble

Pulls a field out of the `drive_resource` list-column into its own
column, placed right after `name`. This is the analogue of
`googledrive::drive_reveal()`. No network requests are made.

Available fields:

- `"type"`: `"file"`, `"folder"`, `"album"`, or `"photo"`.

- `"media_type"`: MIME type, such as `"text/csv"`.

- `"size"`: size in bytes of the active revision, as reported by the
  uploader. `NA` for folders.

- `"storage_size"`: encrypted size of all revisions on the server.

- `"created_time"`, `"modified_time"`, `"trashed_time"`: server
  timestamps, as `POSIXct`. "Modified" means renamed or moved, as well
  as new content.

- `"content_modified_time"`: the file's modification time on the
  uploader's computer.

- `"shared"`, `"shared_by_url"`: logical sharing flags.

- `"role"`: your role set directly on the node.

- `"owner"`: the owner's email address.

- `"author"`: the email of whoever created the node.

- `"sha1"`: SHA-1 of the content, as reported by the uploader.

- `"parent_id"`, `"revision_id"`: related IDs.

## Usage

``` r
pd_reveal(file, what = c("type", "size", "modified_time"))
```

## Arguments

- file:

  A
  [dribble](https://hinkelman.github.io/protondrive/reference/dribble.md),
  or something
  [`as_dribble()`](https://hinkelman.github.io/protondrive/reference/as_dribble.md)
  accepts.

- what:

  The fields to reveal. One or more of those listed above.

## Value

A
[dribble](https://hinkelman.github.io/protondrive/reference/dribble.md)
with extra columns.

## Examples

``` r
if (FALSE) { # \dontrun{
pd_ls() |> pd_reveal(c("size", "modified_time"))
} # }
```
