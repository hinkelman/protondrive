#' Get Proton Drive files by path or ID
#'
#' @description
#' Retrieves metadata for files or folders, given their paths or IDs, and
#' returns it as a [dribble]. This is the analogue of
#' [googledrive::drive_get()].
#'
#' Paths are virtual and always use forward slashes. Your own files live under
#' `/my-files`, which is also where relative paths and `~` point. Other
#' top-level sections are `/devices`, `/shared-with-me`, `/shared-by-me`,
#' `/trash`, `/photos`, and `/albums`. A literal `/` in a file name is written
#' as `\/`.
#'
#' @param path Character vector of paths, such as `"reports/q3.csv"` or
#'   `"/shared-with-me/Team/plan.docx"`. A character vector marked with
#'   [as_id()] is treated as IDs.
#' @param id Character vector of node IDs. Supply `path` or `id`, not both.
#'
#' @return A [dribble] with one row per input.
#' @export
#' @examples
#' \dontrun{
#' pd_get("reports/q3.csv")
#' pd_get(c("~/data", "/shared-with-me/Team"))
#' pd_get(id = "vol...~node...")
#' }
pd_get <- function(path = NULL, id = NULL) {
  if (!is.null(path) && inherits(path, "pd_id")) {
    id <- path
    path <- NULL
  }
  if (is.null(path) == is.null(id)) {
    cli::cli_abort("Supply exactly one of {.arg path} or {.arg id}.")
  }

  if (!is.null(id)) {
    id <- vctrs::vec_data(as_id(id))
    bad <- !is_node_uid(id)
    if (any(bad)) {
      cli::cli_abort("{.val {id[bad]}} {?is/are} not {?a/} valid node ID{?s}.")
    }
    address <- paste0("/my-files/", id)
    path <- rep(NA_character_, length(id))
  } else {
    path <- normalize_path(path)
    address <- path
  }

  rows <- Map(
    function(addr, p) {
      node <- pd_cli("filesystem", "info", addr)
      dribble_from_nodes(list(node), path = p)
    },
    address,
    path
  )
  dribble_rbind(unname(rows))
}

# Look up a single node, returning `NULL` instead of an error if it is absent.
pd_get_maybe <- function(address) {
  tryCatch(
    dribble_from_nodes(list(pd_cli("filesystem", "info", address)), address),
    protondrive_error = function(e) {
      if (inherits(e, "protondrive_auth_error")) {
        rlang::cnd_signal(e)
      }
      NULL
    }
  )
}

# Refresh metadata for nodes after an operation, keeping their known paths.
pd_refresh <- function(x, path = x$path) {
  x <- as_dribble(x)
  if (nrow(x) == 0) {
    return(x)
  }
  out <- pd_get(id = x$id)
  out$path <- path
  out
}
