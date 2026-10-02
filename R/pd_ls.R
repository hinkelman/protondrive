#' List the contents of a Proton Drive folder
#'
#' @description
#' Lists the files and folders inside a folder, as a [dribble]. This is the
#' analogue of [googledrive::drive_ls()].
#'
#' Some paths are special:
#'
#' * `"/"` lists the top-level sections.
#' * `"/devices"` lists your computers backed up to Proton Drive.
#' * `"/shared-with-me"` and `"/shared-by-me"` list shared items.
#' * `"/trash"` lists trashed items.
#'
#' @param path A folder, given as a path, an ID marked with [as_id()], or a
#'   one-row [dribble]. Defaults to `/my-files`.
#' @param pattern A regular expression. Only names that match are returned.
#' @param type Only return nodes of this type, such as `"file"` or
#'   `"folder"`.
#' @param recursive If `TRUE`, also list the contents of sub-folders.
#'   Proton asks that third-party clients avoid frequent recursive
#'   traversals, so use this sparingly on large trees.
#' @param ... Not used.
#'
#' @return A [dribble].
#' @export
#' @examples
#' \dontrun{
#' pd_ls()
#' pd_ls("reports", pattern = "\\.csv$")
#' pd_ls("/shared-with-me")
#' pd_ls("/trash")
#' }
pd_ls <- function(path = NULL, pattern = NULL, type = NULL,
                  recursive = FALSE, ...) {
  rlang::check_dots_empty()
  folder <- resolve_folder(path)

  out <- ls_one(folder$address, folder$path, recursive = recursive)

  if (!is.null(type)) {
    out <- out[node_field(out, "type") %in% type, ]
  }
  if (!is.null(pattern)) {
    out <- out[grepl(pattern, out$name), ]
  }
  out
}

# Resolve a folder argument to the address the CLI needs and the path we
# should report, without an extra round trip when given a plain path.
resolve_folder <- function(path, call = rlang::caller_env()) {
  if (is.null(path)) {
    path <- "/my-files"
  }
  if (is.character(path) && !inherits(path, "pd_id")) {
    check_single(path, "path", call = call)
    path <- normalize_path(path, call = call)
    return(list(address = path, path = path, dribble = NULL))
  }
  x <- as_dribble(path, call = call)
  check_single(x, "path", call = call)
  list(address = pd_address(x, call = call), path = x$path, dribble = x)
}

ls_one <- function(address, path, recursive) {
  section <- path_section(path)
  is_root <- identical(address, "/")
  listing <- pd_cli("filesystem", "list", address)

  if (is_root) {
    return(dribble(
      name = vapply(listing, function(x) sub("^/", "", x$path), character(1)),
      path = vapply(listing, function(x) x$path, character(1)),
      drive_resource = lapply(listing, function(x) list(type = "section"))
    ))
  }

  if (identical(address, "/devices")) {
    return(ls_devices(listing))
  }

  child_path <- if (is.na(section) || section %in% c(drive_sections, trash_sections)) {
    path_join(if (is.na(path)) address else path, vapply(listing, node_name, character(1)))
  } else {
    NA_character_
  }
  # `/shared-by-me` holds nodes that live elsewhere in your tree.
  if (identical(path, "/shared-by-me") || identical(path, "/photos-shared-by-me")) {
    child_path <- NA_character_
  }
  out <- dribble_from_nodes(listing, path = child_path)

  if (!recursive || nrow(out) == 0) {
    return(out)
  }
  if (!is.na(section) && section %in% trash_sections) {
    return(out)
  }
  folders <- out[node_field(out, "type") == "folder", ]
  children <- Map(
    function(addr, p) ls_one(addr, p, recursive = TRUE),
    pd_address(folders),
    folders$path
  )
  dribble_rbind(c(list(out), unname(children)))
}

ls_devices <- function(devices) {
  if (length(devices) == 0) {
    return(new_dribble())
  }
  names <- vapply(devices, node_name, character(1))
  dribble(
    name = names,
    path = path_join("/devices", names),
    id = vapply(devices, function(d) d$rootFolderUid %||% NA_character_, character(1)),
    drive_resource = lapply(devices, function(d) c(d, list(type = "device")))
  )
}

check_single <- function(x, arg, call = rlang::caller_env()) {
  n <- if (is.data.frame(x)) nrow(x) else length(x)
  if (n != 1) {
    cli::cli_abort(
      "{.arg {arg}} must identify exactly one file or folder, not {n}.",
      call = call
    )
  }
  invisible(x)
}
