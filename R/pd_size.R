#' Total size of Proton Drive folders
#'
#' @description
#' Calculates the total size of each folder and how many items it holds,
#' counting all descendants, including trashed ones. The calculation runs on
#' the server; nothing is downloaded.
#'
#' @param file Folders, as paths, IDs marked with [as_id()], or a [dribble].
#'
#' @return A tibble with columns `name`, `path`, `size` (bytes), and
#'   `n_items`.
#' @export
#' @examples
#' \dontrun{
#' pd_size("~")
#' pd_ls(type = "folder") |> pd_size()
#' }
pd_size <- function(file) {
  file <- as_dribble(file)
  sizes <- lapply(pd_address(file), function(a) pd_cli("filesystem", "size", a))
  tibble::tibble(
    name = file$name,
    path = file$path,
    size = vapply(sizes, function(s) as.numeric(s$size %||% NA), numeric(1)),
    n_items = vapply(
      sizes,
      function(s) as.integer(s$numberOfDescendants %||% NA),
      integer(1)
    )
  )
}
