#' Upload files or folders to Proton Drive
#'
#' @description
#' * `pd_upload()` uploads a local file or folder. It is the analogue of
#'   [googledrive::drive_upload()].
#' * `pd_put()` uploads a file, or adds a new revision if a file of that name
#'   already exists. It is the analogue of [googledrive::drive_put()].
#' * `pd_update()` uploads new content for an existing Proton Drive file, as a
#'   new revision. It is the analogue of [googledrive::drive_update()].
#'
#' New revisions keep the file's ID, sharing settings, and version history.
#' The Proton Drive CLI skips uploads whose content is identical to the
#' existing file.
#'
#' @param media Path to a local file or folder.
#' @param path Destination folder, given as a path, an ID marked with
#'   [as_id()], or a one-row [dribble]. Defaults to `/my-files`.
#' @param name Name for the uploaded file or folder. Defaults to the local
#'   name.
#' @param overwrite What to do if something called `name` already exists in
#'   `path`. If `FALSE` (the default) the upload fails. If `TRUE`, a file is
#'   uploaded as a new revision of the existing file and a folder's contents
#'   are merged into the existing folder.
#' @param thumbnails If `TRUE`, the CLI generates preview thumbnails for
#'   images. Set to `FALSE` if thumbnail generation fails on your system.
#' @param file The Proton Drive file to update, as a path, an ID marked with
#'   [as_id()], or a one-row [dribble].
#'
#' @return A one-row [dribble] for the uploaded file or folder, invisibly.
#' @export
#' @examples
#' \dontrun{
#' write.csv(mtcars, "mtcars.csv")
#' pd_upload("mtcars.csv", path = "data")
#' pd_put("mtcars.csv", path = "data")
#'
#' f <- pd_get("data/mtcars.csv")
#' pd_update(f, "mtcars.csv")
#' }
pd_upload <- function(media, path = NULL, name = NULL, overwrite = FALSE,
                      thumbnails = TRUE) {
  check_string(media, "media")
  if (!file.exists(media)) {
    cli::cli_abort("Local file {.file {media}} does not exist.")
  }
  media <- normalizePath(media, mustWork = TRUE)
  name <- name %||% basename(media)
  check_string(name, "name")

  parent <- resolve_folder(path)
  local <- stage_local(media, name)

  summary <- pd_cli(
    "filesystem", "upload",
    c(local, parent$address),
    options = list(
      "file-conflict-strategy" = if (isTRUE(overwrite)) "create-new-revision",
      "folder-conflict-strategy" = if (isTRUE(overwrite)) "merge",
      "skip-thumbnails" = !thumbnails
    )
  )

  location <- path_join(child_parent_path_of(parent), name)
  if (transfer_count(summary, "skippedItems") > 0 &&
      transfer_count(summary, "transferredItems") == 0) {
    pd_inform(c(
      "i" = "{.file {location}} already has identical content; nothing uploaded."
    ))
  } else {
    pd_inform(c(
      "v" = "Uploaded {.file {media}} to {.file {location}}.",
      transfer_note(summary)
    ))
  }

  out <- pd_get_maybe(path_join(parent$address, name))
  if (!is.null(out)) {
    out$path <- location
  }
  invisible(out)
}

#' @rdname pd_upload
#' @export
pd_put <- function(media, path = NULL, name = NULL, thumbnails = TRUE) {
  pd_upload(media, path = path, name = name, overwrite = TRUE,
            thumbnails = thumbnails)
}

#' @rdname pd_upload
#' @export
pd_update <- function(file, media, thumbnails = TRUE) {
  file <- as_dribble(file)
  check_single(file, "file")
  if (!identical(node_field(file, "type"), "file")) {
    cli::cli_abort("{.arg file} must be a file, not a {node_field(file, 'type')}.")
  }
  parent_id <- node_field(file, "parentUid")
  parent <- dribble(
    name = "parent",
    path = if (is.na(file$path)) NA_character_ else path_parent(file$path),
    id = parent_id
  )
  out <- pd_upload(media, path = parent, name = file$name, overwrite = TRUE,
                   thumbnails = thumbnails)
  invisible(out)
}

# The CLI uploads under the local name, so copy to a temporary location when
# a different remote name is wanted.
stage_local <- function(media, name, env = rlang::caller_env()) {
  if (identical(basename(media), name)) {
    return(media)
  }
  stage <- withr::local_tempdir(.local_envir = env)
  target <- file.path(stage, name)
  if (dir.exists(media)) {
    dir.create(target)
    ok <- all(file.copy(
      list.files(media, full.names = TRUE, all.files = TRUE, no.. = TRUE),
      target,
      recursive = TRUE,
      copy.date = TRUE
    ))
  } else {
    ok <- file.copy(media, target, copy.date = TRUE)
  }
  if (!ok) {
    cli::cli_abort("Failed to stage {.file {media}} for upload as {.val {name}}.")
  }
  target
}

transfer_count <- function(summary, field) {
  as.numeric(summary[[field]] %||% 0)
}

transfer_note <- function(summary) {
  n <- transfer_count(summary, "transferredItems")
  bytes <- transfer_count(summary, "transferredBytes")
  skipped <- transfer_count(summary, "skippedItems")
  note <- c("i" = cli::format_inline(
    "{n} item{?s}, {format_bytes(bytes)}."
  ))
  if (skipped > 0) {
    note <- c(note, "i" = cli::format_inline(
      "{skipped} item{?s} skipped (identical content or not downloadable)."
    ))
  }
  note
}

format_bytes <- function(x) {
  units <- c("B", "KiB", "MiB", "GiB", "TiB")
  i <- if (x <= 0) 1 else min(floor(log(x, 1024)) + 1, length(units))
  if (i == 1) {
    return(paste(x, "B"))
  }
  sprintf("%.2f %s", x / 1024^(i - 1), units[[i]])
}
