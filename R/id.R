#' Mark strings as Proton Drive node IDs
#'
#' @description
#' Every file and folder on Proton Drive has a unique ID (a "node UID") of the
#' form `<volume id>~<node id>`. `as_id()` marks a character vector as IDs, so
#' that functions like [pd_get()] treat them as IDs rather than paths. It is
#' the analogue of [googledrive::as_id()].
#'
#' Unlike paths, IDs keep working after a file is renamed or moved.
#'
#' @param x A character vector of IDs, a [dribble], or a data frame with an
#'   `id` column.
#' @param ... Not used.
#'
#' @return A character vector with class `pd_id`.
#' @export
#' @examples
#' as_id("vol0000000000000000001~node00000000000000001")
#'
#' \dontrun{
#' as_id(pd_ls())
#' }
as_id <- function(x, ...) {
  UseMethod("as_id")
}

#' @export
as_id.default <- function(x, ...) {
  cli::cli_abort(
    "Don't know how to coerce an object of class {.cls {class(x)}} into a {.cls pd_id}."
  )
}

#' @export
as_id.NULL <- function(x, ...) {
  NULL
}

#' @export
as_id.pd_id <- function(x, ...) {
  x
}

#' @export
as_id.character <- function(x, ...) {
  new_pd_id(unname(x))
}

#' @export
as_id.data.frame <- function(x, ...) {
  if (!"id" %in% names(x)) {
    cli::cli_abort("A data frame needs an {.field id} column to be coerced to IDs.")
  }
  new_pd_id(as.character(x$id))
}

new_pd_id <- function(x = character()) {
  vctrs::new_vctr(as.character(x), class = "pd_id", inherit_base_type = TRUE)
}

#' @export
format.pd_id <- function(x, ...) {
  out <- vctrs::vec_data(x)
  out[is.na(out)] <- NA_character_
  out
}

#' @export
print.pd_id <- function(x, ...) {
  cat("<pd_id[", length(x), "]>\n", sep = "")
  if (length(x) > 0) {
    print(vctrs::vec_data(x), quote = FALSE)
  }
  invisible(x)
}

#' @exportS3Method pillar::pillar_shaft
pillar_shaft.pd_id <- function(x, ...) {
  pillar::new_pillar_shaft_simple(
    pillar::style_subtle(abbreviate_id(vctrs::vec_data(x))),
    min_width = 10
  )
}

#' @exportS3Method vctrs::vec_ptype_abbr
vec_ptype_abbr.pd_id <- function(x, ...) {
  "pd_id"
}

#' @exportS3Method vctrs::vec_ptype2 pd_id.pd_id
vec_ptype2.pd_id.pd_id <- function(x, y, ...) new_pd_id()
#' @exportS3Method vctrs::vec_ptype2 pd_id.character
vec_ptype2.pd_id.character <- function(x, y, ...) character()
#' @exportS3Method vctrs::vec_ptype2 character.pd_id
vec_ptype2.character.pd_id <- function(x, y, ...) character()
#' @exportS3Method vctrs::vec_cast pd_id.pd_id
vec_cast.pd_id.pd_id <- function(x, to, ...) x
#' @exportS3Method vctrs::vec_cast pd_id.character
vec_cast.pd_id.character <- function(x, to, ...) new_pd_id(x)
#' @exportS3Method vctrs::vec_cast character.pd_id
vec_cast.character.pd_id <- function(x, to, ...) vctrs::vec_data(x)

# Node UIDs are long; show the start and end, which is what people compare.
abbreviate_id <- function(x, width = 24) {
  long <- !is.na(x) & nchar(x) > width
  tail <- (width - 1) %/% 2
  head <- width - 1 - tail
  x[long] <- paste0(
    substr(x[long], 1, head),
    "\u2026",
    substr(x[long], nchar(x[long]) - tail + 1, nchar(x[long]))
  )
  x
}

# Mirrors `isNodeUid()` in the CLI (cli/src/cli/paths.ts). Only strings that
# match are resolved by the CLI as IDs when they appear as a path segment.
is_node_uid <- function(x) {
  part <- "([a-zA-Z0-9=_-]{88,108}|[a-zA-Z0-9_-]{22})"
  !is.na(x) & grepl(paste0("^", part, "~", part, "$"), x)
}
