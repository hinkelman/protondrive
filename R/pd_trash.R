#' Move Proton Drive files to or from the trash
#'
#' @description
#' * `pd_trash()` moves files or folders to the trash. It is the analogue of
#'   [googledrive::drive_trash()].
#' * `pd_untrash()` restores them. It is the analogue of
#'   [googledrive::drive_untrash()].
#' * `pd_empty_trash()` permanently deletes everything in `/trash`. It is the
#'   analogue of [googledrive::drive_empty_trash()]. Photos in
#'   `/photos-trash` are not affected. Deletion happens asynchronously on the
#'   server.
#'
#' The Proton Drive CLI identifies items in the trash by name. If the trash
#' holds several items with the same name, `pd_untrash()` refuses to guess
#' and asks you to resolve the ambiguity.
#'
#' @param file Files or folders, as paths, IDs marked with [as_id()], or a
#'   [dribble]. For `pd_untrash()`, typically a dribble from
#'   `pd_ls("/trash")` or from `pd_trash()`.
#' @param verbose If `TRUE`, report what happened.
#'
#' @return `pd_trash()` and `pd_untrash()` return a [dribble] of the affected
#'   items, invisibly. `pd_empty_trash()` returns `NULL`, invisibly.
#' @export
#' @examples
#' \dontrun{
#' trashed <- pd_trash("data/old.csv")
#' pd_ls("/trash")
#' pd_untrash(trashed)
#' pd_empty_trash()
#' }
pd_trash <- function(file, verbose = TRUE) {
  file <- as_dribble(file)
  if (nrow(file) == 0) {
    return(invisible(file))
  }
  results <- pd_cli("filesystem", "trash", pd_address(file))
  check_node_results(results, file, "trash")

  file$path <- trash_path(file)
  if (verbose) {
    pd_inform(c("v" = "Moved {nrow(file)} item{?s} to the trash:",
                      bullets(file$name)))
  }
  invisible(file)
}

#' @rdname pd_trash
#' @export
pd_untrash <- function(file, verbose = TRUE) {
  file <- as_dribble(file)
  if (nrow(file) == 0) {
    return(invisible(file))
  }
  address <- trash_address(file)
  results <- pd_cli("filesystem", "restore", address)
  check_node_results(results, file, "restore")

  out <- pd_refresh(file, path = rep(NA_character_, nrow(file)))
  if (verbose) {
    pd_inform(c("v" = "Restored {nrow(out)} item{?s} from the trash:",
                      bullets(out$name)))
  }
  invisible(out)
}

#' @rdname pd_trash
#' @export
pd_empty_trash <- function(verbose = TRUE) {
  pd_cli("filesystem", "empty-trash", parse = FALSE)
  if (verbose) {
    pd_inform(c("v" = "Emptied the trash. Deletion completes in the background."))
  }
  invisible()
}

#' Permanently delete Proton Drive files
#'
#' @description
#' Permanently deletes files or folders, moving them to the trash first if
#' needed. **This can't be undone.** This is the analogue of
#' [googledrive::drive_rm()]. Use [pd_trash()] for a reversible alternative.
#'
#' @inheritParams pd_trash
#'
#' @return A [dribble] of the deleted items, invisibly.
#' @export
#' @examples
#' \dontrun{
#' pd_rm("data/scratch.csv")
#' }
pd_rm <- function(file, verbose = TRUE) {
  file <- as_dribble(file)
  if (nrow(file) == 0) {
    return(invisible(file))
  }
  in_trash <- path_section(file$path) %in% trash_sections
  if (any(!in_trash)) {
    file[!in_trash, ] <- pd_trash(file[!in_trash, ], verbose = FALSE)
  }

  address <- trash_address(file)
  results <- pd_cli("filesystem", "delete", address)
  check_node_results(results, file, "delete")

  if (verbose) {
    pd_inform(c("v" = "Permanently deleted {nrow(file)} item{?s}:",
                      bullets(file$name)))
  }
  invisible(file)
}

# Where an item sits once trashed. Photos have a trash of their own.
trash_path <- function(file) {
  section <- path_section(file$path)
  is_photo <- section %in% c(photo_sections, "photos-trash") |
    node_field(file, "type") %in% c("photo", "album")
  trash <- ifelse(is_photo, "/photos-trash", "/trash")
  path_join(trash, file$name)
}

# The CLI looks items up in the trash by name and takes the first match, so
# confirm that each name is unambiguous and refers to the node we mean before
# handing it over. Getting this wrong could restore or delete the wrong item.
trash_address <- function(file, call = rlang::caller_env()) {
  address <- trash_path(file)
  ids <- vctrs::vec_data(file$id)

  for (trash in unique(path_parent(address))) {
    listing <- pd_cli("filesystem", "list", trash)
    names <- vapply(listing, node_name, character(1))
    uids <- vapply(listing, function(n) n$uid %||% NA_character_, character(1))

    rows <- which(path_parent(address) == trash)
    for (i in rows) {
      matches <- which(names == file$name[[i]])
      if (length(matches) == 0) {
        cli::cli_abort(
          "{.val {file$name[[i]]}} is not in {.file {trash}}.",
          call = call
        )
      }
      if (length(matches) > 1) {
        cli::cli_abort(
          c(
            "{.file {trash}} holds {length(matches)} items named {.val {file$name[[i]]}}.",
            "x" = "The Proton Drive CLI identifies trashed items by name, so
                   protondrive can't tell which one you mean.",
            "i" = "Restore and rename the others first, or use the Proton
                   Drive web app."
          ),
          call = call
        )
      }
      if (!is.na(ids[[i]]) && !identical(uids[[matches]], ids[[i]])) {
        cli::cli_abort(
          c(
            "The item named {.val {file$name[[i]]}} in {.file {trash}} is not the one you supplied.",
            "i" = "Expected ID {.val {ids[[i]]}}, found {.val {uids[[matches]]}}."
          ),
          call = call
        )
      }
    }
  }
  address
}

bullets <- function(x, max = 10) {
  shown <- utils::head(x, max)
  out <- rlang::set_names(
    vapply(shown, function(s) cli::format_inline("{.val {s}}"), character(1)),
    rep("*", length(shown))
  )
  if (length(x) > max) {
    out <- c(out, "*" = paste0("\u2026 and ", length(x) - max, " more"))
  }
  out
}
