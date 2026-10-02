#' Create a folder on Proton Drive
#'
#' @description
#' Creates a new folder. This is the analogue of
#' [googledrive::drive_mkdir()].
#'
#' @param name Name of the new folder. It may include a path, such as
#'   `"reports/2026"`, in which case `path` must not be given and the parent
#'   (here `reports`) must already exist.
#' @param path Parent folder, given as a path, an ID marked with [as_id()], or
#'   a one-row [dribble]. Defaults to `/my-files`.
#' @param overwrite What to do if a file or folder called `name` already
#'   exists in `path`. Proton Drive never allows two items with the same name
#'   in one folder, so `FALSE` (the default) is an error, while `TRUE` moves
#'   the existing item to the trash first.
#'
#' @return A one-row [dribble] for the new folder, invisibly.
#' @export
#' @examples
#' \dontrun{
#' pd_mkdir("analysis")
#' pd_mkdir("figures", path = "analysis")
#' pd_mkdir("analysis/tables")
#' }
pd_mkdir <- function(name, path = NULL, overwrite = FALSE) {
  check_string(name, "name")
  if (is.null(path) && grepl("/", gsub("\\/", "", name, fixed = TRUE))) {
    full <- normalize_path(name)
    path <- path_parent(full)
    name <- path_basename(full)
  }
  parent <- resolve_folder(path)
  check_no_conflict(parent, name, overwrite)

  node <- pd_cli("filesystem", "create-folder", c(parent$address, name))
  out <- dribble_from_nodes(
    list(node),
    path = path_join(child_parent_path_of(parent), name)
  )
  pd_inform(c("v" = "Created folder {.file {display_path(out)}}."))
  invisible(out)
}

child_parent_path_of <- function(folder) {
  if (is.na(folder$path)) folder$address else folder$path
}

# Proton Drive rejects duplicate names within a folder. With
# `overwrite = TRUE`, trash the existing node so the new one can take its name.
check_no_conflict <- function(parent, name, overwrite,
                              call = rlang::caller_env()) {
  existing <- pd_get_maybe(path_join(parent$address, name))
  if (is.null(existing)) {
    return(invisible(NULL))
  }
  if (!isTRUE(overwrite)) {
    cli::cli_abort(
      c(
        "{.val {name}} already exists in {.file {child_parent_path_of(parent)}}.",
        "i" = "Use {.code overwrite = TRUE} to move the existing item to the trash first."
      ),
      class = "protondrive_conflict",
      call = call
    )
  }
  pd_trash(existing, verbose = FALSE)
  pd_inform(c("i" = "Moved existing {.val {name}} to the trash."))
  invisible(existing)
}
