#' dribble object
#'
#' @description
#' protondrive stores metadata about Proton Drive files and folders in a
#' dribble (a **dr**ive t**ibble**), just as googledrive does. It is a tibble
#' with one row per file or folder and these columns:
#'
#' * `name`: the file or folder name.
#' * `path`: the virtual path used to reach it, such as
#'   `"/my-files/reports/q3.csv"`. It is `NA` when the node was looked up by
#'   ID or listed in `/shared-by-me`, where the CLI does not report a path.
#'   Paths are a snapshot: they go stale if the node is renamed or moved
#'   elsewhere, but protondrive addresses nodes by `id` where it can, so a
#'   stale path does no harm.
#' * `id`: the node UID, of class `pd_id`. See [as_id()].
#' * `drive_resource`: a list-column holding the full metadata the Proton
#'   Drive SDK returns for the node: type, media type, sizes, timestamps,
#'   authors, sharing state, active revision, and more. Use [pd_reveal()] to
#'   pull fields out into their own columns.
#'
#' A dribble survives most dplyr verbs and base subsetting. If you drop or
#' change one of the required columns, it reverts to a plain tibble.
#'
#' @section Relationship to googledrive:
#' A protondrive dribble has the same role and columns as a googledrive
#' dribble, plus `path`. Its S3 class is `pd_dribble` rather than `dribble`,
#' so the two packages' methods never apply to each other's objects, and the
#' two kinds of dribble can't be mixed. Both packages export `as_dribble()`
#' and `is_dribble()`; if you attach both, call them with a `protondrive::`
#' or `googledrive::` prefix.
#'
#' @name dribble
#' @seealso [as_dribble()], [is_dribble()]
NULL

dribble_cols <- c("name", "path", "id", "drive_resource")

new_dribble <- function(x = list()) {
  if (length(x) == 0) {
    x <- list(
      name = character(),
      path = character(),
      id = new_pd_id(),
      drive_resource = list()
    )
  }
  x$id <- new_pd_id(vctrs::vec_data(x$id))
  tibble::new_tibble(x, class = "pd_dribble", nrow = length(x$name))
}

dribble <- function(name = character(), path = NA_character_,
                    id = NA_character_, drive_resource = list(list())) {
  n <- length(name)
  if (n == 0) {
    return(new_dribble())
  }
  new_dribble(list(
    name = as.character(name),
    path = vctrs::vec_recycle(as.character(path), n),
    id = vctrs::vec_recycle(as.character(id), n),
    drive_resource = vctrs::vec_recycle(drive_resource, n)
  ))
}

dribble_problems <- function(x) {
  missing <- setdiff(dribble_cols, names(x))
  if (length(missing) > 0) {
    return(cli::format_inline("Missing column{?s}: {.field {missing}}"))
  }
  problems <- character()
  if (!is.character(x$name)) {
    problems <- c(problems, "{.field name} must be character")
  }
  if (!is.character(x$path)) {
    problems <- c(problems, "{.field path} must be character")
  }
  if (!is.character(x$id)) {
    problems <- c(problems, "{.field id} must be character")
  }
  if (!is.list(x$drive_resource)) {
    problems <- c(problems, "{.field drive_resource} must be a list")
  }
  problems
}

#' Coerce to a dribble
#'
#' @description
#' Converts various inputs into a [dribble]. This is how every protondrive
#' function interprets its `file` and `path` arguments:
#'
#' * A dribble is returned as is.
#' * A character vector is treated as paths and looked up with [pd_get()].
#' * A character vector marked with [as_id()] is looked up by ID.
#' * A data frame with the columns of a dribble is validated and converted.
#'
#' @param x An object to coerce.
#' @param ... Not used.
#' @param call The execution environment of a currently running function,
#'   used in error messages.
#'
#' @return A dribble.
#' @export
#' @examples
#' \dontrun{
#' as_dribble("reports/q3.csv")
#' as_dribble(as_id("vol...~node..."))
#' }
as_dribble <- function(x, ..., call = rlang::caller_env()) {
  UseMethod("as_dribble")
}

#' @export
as_dribble.default <- function(x, ..., call = rlang::caller_env()) {
  cli::cli_abort(
    "Don't know how to coerce an object of class {.cls {class(x)}} into a dribble.",
    call = call
  )
}

#' @export
as_dribble.pd_dribble <- function(x, ..., call = rlang::caller_env()) {
  x
}

#' @export
as_dribble.data.frame <- function(x, ..., call = rlang::caller_env()) {
  problems <- dribble_problems(x)
  if (length(problems) > 0) {
    cli::cli_abort(
      c("Can't coerce this data frame to a dribble.", rlang::set_names(problems, "x")),
      call = call
    )
  }
  new_dribble(as.list(x[dribble_cols]))
}

#' @export
as_dribble.character <- function(x, ..., call = rlang::caller_env()) {
  pd_get(path = x)
}

#' @export
as_dribble.pd_id <- function(x, ..., call = rlang::caller_env()) {
  pd_get(id = x)
}

#' @export
as_dribble.NULL <- function(x, ..., call = rlang::caller_env()) {
  new_dribble()
}

#' Is this a dribble?
#'
#' @param x An object.
#' @return `TRUE` if `x` is a [dribble], `FALSE` otherwise.
#' @export
#' @examples
#' is_dribble(mtcars)
is_dribble <- function(x) {
  inherits(x, "pd_dribble")
}

# Downgrade to a tibble when an operation breaks the dribble invariants.
maybe_dribble <- function(x) {
  if (is.data.frame(x) && length(dribble_problems(x)) == 0) {
    if (!is_dribble(x)) {
      x <- new_dribble(as.list(x))
    }
    return(x)
  }
  if (is.data.frame(x)) {
    class(x) <- setdiff(class(x), "pd_dribble")
  }
  x
}

#' @export
`[.pd_dribble` <- function(x, i, j, drop = FALSE) {
  maybe_dribble(NextMethod())
}

#' @export
`names<-.pd_dribble` <- function(x, value) {
  maybe_dribble(NextMethod())
}

#' @exportS3Method pillar::tbl_sum
tbl_sum.pd_dribble <- function(x, ...) {
  out <- NextMethod()
  names(out)[[1]] <- "A dribble"
  out
}

#' @exportS3Method vctrs::vec_restore
vec_restore.pd_dribble <- function(x, to, ...) {
  maybe_dribble(tibble::new_tibble(x, nrow = vctrs::vec_size(x)))
}

#' @exportS3Method vctrs::vec_ptype2 pd_dribble.pd_dribble
vec_ptype2.pd_dribble.pd_dribble <- function(x, y, ...) {
  maybe_dribble(vctrs::tib_ptype2(x, y, ...))
}
#' @exportS3Method vctrs::vec_ptype2 pd_dribble.tbl_df
vec_ptype2.pd_dribble.tbl_df <- function(x, y, ...) vctrs::tib_ptype2(x, y, ...)
#' @exportS3Method vctrs::vec_ptype2 tbl_df.pd_dribble
vec_ptype2.tbl_df.pd_dribble <- function(x, y, ...) vctrs::tib_ptype2(x, y, ...)
#' @exportS3Method vctrs::vec_ptype2 pd_dribble.data.frame
vec_ptype2.pd_dribble.data.frame <- function(x, y, ...) vctrs::tib_ptype2(x, y, ...)
#' @exportS3Method vctrs::vec_ptype2 data.frame.pd_dribble
vec_ptype2.data.frame.pd_dribble <- function(x, y, ...) vctrs::tib_ptype2(x, y, ...)

#' @exportS3Method vctrs::vec_cast pd_dribble.pd_dribble
vec_cast.pd_dribble.pd_dribble <- function(x, to, ...) {
  maybe_dribble(vctrs::tib_cast(x, to, ...))
}
#' @exportS3Method vctrs::vec_cast pd_dribble.tbl_df
vec_cast.pd_dribble.tbl_df <- function(x, to, ...) {
  maybe_dribble(vctrs::tib_cast(x, to, ...))
}
#' @exportS3Method vctrs::vec_cast tbl_df.pd_dribble
vec_cast.tbl_df.pd_dribble <- function(x, to, ...) vctrs::tib_cast(x, to, ...)
#' @exportS3Method vctrs::vec_cast pd_dribble.data.frame
vec_cast.pd_dribble.data.frame <- function(x, to, ...) {
  maybe_dribble(vctrs::tib_cast(x, to, ...))
}
#' @exportS3Method vctrs::vec_cast data.frame.pd_dribble
vec_cast.data.frame.pd_dribble <- function(x, to, ...) vctrs::df_cast(x, to, ...)

#' @exportS3Method dplyr::dplyr_reconstruct
dplyr_reconstruct.pd_dribble <- function(data, template) {
  maybe_dribble(tibble::new_tibble(as.list(data), nrow = nrow(data)))
}

# Rows from SDK node objects ---------------------------------------------------

# A node's display name, following `getName()` in the CLI: the decrypted
# name, else the placeholder from an invalid-name error, else the UID.
node_name <- function(node) {
  name <- node$name
  if (is.list(name) && isTRUE(name$ok) && is.character(name$value)) {
    if (nzchar(name$value)) {
      return(name$value)
    }
  } else if (is.list(name) && is.list(name$error) &&
             is.character(name$error$name)) {
    return(name$error$name)
  }
  node$uid %||% NA_character_
}

dribble_from_nodes <- function(nodes, path = NA_character_) {
  if (length(nodes) == 0) {
    return(new_dribble())
  }
  dribble(
    name = vapply(nodes, node_name, character(1)),
    path = path,
    id = vapply(nodes, function(n) n$uid %||% NA_character_, character(1)),
    drive_resource = nodes
  )
}

dribble_rbind <- function(xs) {
  xs <- Filter(function(x) nrow(x) > 0, xs)
  if (length(xs) == 0) {
    return(new_dribble())
  }
  new_dribble(as.list(vctrs::vec_rbind(!!!lapply(xs, tibble::as_tibble))))
}
