#' Copy a Proton Drive file or folder
#'
#' @description
#' Copies a file or folder, possibly into a different folder. This is the
#' analogue of [googledrive::drive_cp()]. Unlike moving, copying works
#' between your files and folders shared with you by other people.
#'
#' @param file The file or folder to copy, as a path, an ID marked with
#'   [as_id()], or a one-row [dribble].
#' @param path Destination folder. Defaults to the folder `file` is in.
#' @param name Name of the copy. Defaults to `"Copy of <name>"` when copying
#'   within the same folder, and to the original name otherwise.
#' @param overwrite What to do if something called `name` already exists in
#'   `path`. `FALSE` (the default) is an error; `TRUE` moves the existing item
#'   to the trash first.
#'
#' @return A one-row [dribble] for the copy, invisibly.
#' @export
#' @examples
#' \dontrun{
#' pd_cp("data/mtcars.csv")
#' pd_cp("data/mtcars.csv", path = "archive", name = "mtcars-2026.csv")
#' }
pd_cp <- function(file, path = NULL, name = NULL, overwrite = FALSE) {
  file <- as_dribble(file)
  check_single(file, "file")

  if (is.null(path)) {
    target <- parent_folder(file)
    name <- name %||% paste("Copy of", file$name)
  } else {
    target <- resolve_folder(path)
    name <- name %||% file$name
  }
  check_string(name, "name")
  check_no_conflict(target, name, overwrite)

  results <- pd_cli(
    "filesystem", "copy",
    c(pd_address(file), target$address),
    options = list(name = name)
  )
  check_node_results(results, file, "copy")

  location <- path_join(child_parent_path_of(target), name)
  out <- pd_get(id = results[[1]]$newUid)
  out$path <- location
  pd_inform(c("v" = "Copied {.file {display_path(file)}} to {.file {location}}."))
  invisible(out)
}

#' Move or rename a Proton Drive file or folder
#'
#' @description
#' * `pd_mv()` moves a file or folder into a different folder, and can
#'   rename it at the same time. It is the analogue of
#'   [googledrive::drive_mv()].
#' * `pd_rename()` renames a file or folder in place. It is the analogue of
#'   [googledrive::drive_rename()].
#'
#' Items can only be moved within the same owner's drive. To move between
#' your files and a folder someone shared with you, use [pd_cp()] and then
#' [pd_trash()].
#'
#' @inheritParams pd_cp
#' @param file The file or folder to move or rename, as a path, an ID marked
#'   with [as_id()], or a one-row [dribble].
#' @param path Destination folder. If `NULL`, the item stays where it is.
#' @param name New name. If `NULL`, the name is unchanged.
#'
#' @return A one-row [dribble] for the item, with updated metadata,
#'   invisibly.
#' @export
#' @examples
#' \dontrun{
#' pd_mv("data/mtcars.csv", path = "archive")
#' pd_mv("data/mtcars.csv", path = "archive", name = "old-mtcars.csv")
#' pd_rename("data/mtcars.csv", "cars.csv")
#' }
pd_mv <- function(file, path = NULL, name = NULL, overwrite = FALSE) {
  if (is.null(path) && is.null(name)) {
    cli::cli_abort("Supply a new {.arg path}, a new {.arg name}, or both.")
  }
  file <- as_dribble(file)
  check_single(file, "file")
  location <- file$path

  if (!is.null(name) && !identical(name, file$name)) {
    file <- pd_rename(file, name, overwrite = overwrite, verbose = FALSE)
    location <- file$path
  }

  if (!is.null(path)) {
    target <- resolve_folder(path)
    check_no_conflict(target, file$name, overwrite)
    results <- pd_cli(
      "filesystem", "move",
      c(pd_address(file), target$address)
    )
    check_node_results(results, file, "move")
    location <- path_join(child_parent_path_of(target), file$name)
  }

  out <- pd_refresh(file, path = location)
  pd_inform(c("v" = "Moved to {.file {display_path(out)}}."))
  invisible(out)
}

#' @rdname pd_mv
#' @param verbose If `TRUE`, report what happened.
#' @export
pd_rename <- function(file, name, overwrite = FALSE, verbose = TRUE) {
  file <- as_dribble(file)
  check_single(file, "file")
  check_string(name, "name")

  parent <- parent_folder(file)
  if (!is.na(parent$address)) {
    check_no_conflict(parent, name, overwrite)
  }

  node <- pd_cli("filesystem", "rename", c(pd_address(file), name))
  location <- if (is.na(file$path)) NA_character_ else path_join(path_parent(file$path), name)
  out <- dribble_from_nodes(list(node), path = location)
  if (verbose) {
    pd_inform(c("v" = "Renamed {.val {file$name}} to {.val {name}}."))
  }
  invisible(out)
}

# The folder containing a node, in the form `resolve_folder()` returns.
parent_folder <- function(file) {
  parent_id <- node_field(file, "parentUid")
  parent_path <- if (is.na(file$path)) NA_character_ else path_parent(file$path)
  address <- if (is_node_uid(parent_id)) {
    paste0("/my-files/", parent_id)
  } else {
    parent_path
  }
  list(address = address, path = parent_path, dribble = NULL)
}

# Bulk operations return one `{uid, ok, error}` result per node and exit
# successfully even when some of them fail.
check_node_results <- function(results, x, verb, call = rlang::caller_env()) {
  failed <- Filter(function(r) !isTRUE(r$ok), results)
  if (length(failed) == 0) {
    return(invisible(results))
  }
  ids <- vctrs::vec_data(x$id)
  msgs <- vapply(failed, function(r) {
    name <- x$name[match(r$uid, ids)]
    if (is.na(name)) {
      name <- r$uid %||% "?"
    }
    paste0(name, ": ", node_error_message(r$error))
  }, character(1))
  cli::cli_abort(
    c(
      "Failed to {verb} {length(failed)} item{?s}.",
      rlang::set_names(msgs, rep("x", length(msgs)))
    ),
    class = "protondrive_error",
    call = call
  )
}

# JavaScript `Error`s lose their message when serialised to JSON, so use
# whatever fields survived.
node_error_message <- function(error) {
  if (is.character(error)) {
    return(error)
  }
  if (is.list(error)) {
    for (field in c("message", "error", "name", "code")) {
      if (length(error[[field]]) == 1 && !is.list(error[[field]])) {
        return(as.character(error[[field]]))
      }
    }
  }
  "the CLI did not report a reason (run the CLI directly for details)"
}
