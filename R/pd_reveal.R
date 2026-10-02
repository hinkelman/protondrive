#' Add a column of Proton Drive metadata to a dribble
#'
#' @description
#' Pulls a field out of the `drive_resource` list-column into its own column,
#' placed right after `name`. This is the analogue of
#' [googledrive::drive_reveal()]. No network requests are made.
#'
#' Available fields:
#'
#' * `"type"`: `"file"`, `"folder"`, `"album"`, or `"photo"`.
#' * `"media_type"`: MIME type, such as `"text/csv"`.
#' * `"size"`: size in bytes of the active revision, as reported by the
#'   uploader. `NA` for folders.
#' * `"storage_size"`: encrypted size of all revisions on the server.
#' * `"created_time"`, `"modified_time"`, `"trashed_time"`: server
#'   timestamps, as `POSIXct`. "Modified" means renamed or moved, as well as
#'   new content.
#' * `"content_modified_time"`: the file's modification time on the
#'   uploader's computer.
#' * `"shared"`, `"shared_by_url"`: logical sharing flags.
#' * `"role"`: your role set directly on the node.
#' * `"owner"`: the owner's email address.
#' * `"author"`: the email of whoever created the node.
#' * `"sha1"`: SHA-1 of the content, as reported by the uploader.
#' * `"parent_id"`, `"revision_id"`: related IDs.
#'
#' @param file A [dribble], or something [as_dribble()] accepts.
#' @param what The fields to reveal. One or more of those listed above.
#'
#' @return A [dribble] with extra columns.
#' @export
#' @examples
#' \dontrun{
#' pd_ls() |> pd_reveal(c("size", "modified_time"))
#' }
pd_reveal <- function(file, what = c("type", "size", "modified_time")) {
  file <- as_dribble(file)
  what <- rlang::arg_match(what, names(reveal_fields), multiple = TRUE)
  for (field in rev(what)) {
    values <- reveal_fields[[field]](file)
    file <- tibble::add_column(file, !!field := values, .after = "name",
                               .name_repair = "minimal")
  }
  maybe_dribble(file)
}

reveal_fields <- list(
  type = function(x) node_field(x, "type"),
  media_type = function(x) node_field(x, "mediaType"),
  size = function(x) node_field(x, c("activeRevision", "claimedSize"), as.numeric),
  storage_size = function(x) node_field(x, "totalStorageSize", as.numeric),
  created_time = function(x) node_field(x, "creationTime", parse_time),
  modified_time = function(x) node_field(x, "modificationTime", parse_time),
  content_modified_time = function(x) {
    node_field(x, c("activeRevision", "claimedModificationTime"), parse_time)
  },
  trashed_time = function(x) node_field(x, "trashTime", parse_time),
  shared = function(x) node_field(x, "isShared", as.logical),
  shared_by_url = function(x) node_field(x, "isSharedByUrl", as.logical),
  role = function(x) node_field(x, "directRole"),
  owner = function(x) node_field(x, c("ownedBy", "email")),
  author = function(x) {
    vapply(x$drive_resource, function(r) author_email(r$keyAuthor), character(1))
  },
  sha1 = function(x) node_field(x, c("activeRevision", "claimedDigests", "sha1")),
  parent_id = function(x) new_pd_id(node_field(x, "parentUid")),
  revision_id = function(x) new_pd_id(node_field(x, c("activeRevision", "uid")))
)

# Extract a (possibly nested) scalar field from every `drive_resource`.
node_field <- function(x, field, transform = as.character) {
  values <- lapply(x$drive_resource, function(r) {
    for (f in field) {
      if (!is.list(r) || is.null(r[[f]])) {
        return(NA)
      }
      r <- r[[f]]
    }
    if (length(r) != 1 || is.list(r)) NA else r
  })
  transform(unlist(values, use.names = FALSE) %||% logical())
}

parse_time <- function(x) {
  x <- as.character(x)
  as.POSIXct(x, format = "%Y-%m-%dT%H:%M:%OSZ", tz = "UTC")
}

# Authors are `Result<string | null, {claimedAuthor, error}>`. Unverified
# authors are shown in parentheses, as the CLI does.
author_email <- function(author) {
  if (!is.list(author)) {
    return(NA_character_)
  }
  if (isTRUE(author$ok)) {
    return(if (is.character(author$value)) author$value else NA_character_)
  }
  claimed <- author$error$claimedAuthor
  if (is.character(claimed)) paste0("(", claimed, ")") else NA_character_
}
