#' Download a file or folder from Proton Drive
#'
#' @description
#' Downloads and decrypts a file or folder to your computer. This is the
#' analogue of [googledrive::drive_download()]. Proton Docs and Sheets
#' cannot be downloaded this way.
#'
#' @param file The file or folder to download, as a path, an ID marked with
#'   [as_id()], or a one-row [dribble].
#' @param path Local path to save to. Defaults to the file's name, in the
#'   working directory.
#' @param overwrite If `FALSE` (the default), it is an error for `path` to
#'   exist already. If `TRUE`, it is replaced.
#'
#' @return A one-row [dribble] for the downloaded file, with an extra
#'   `local_path` column, invisibly.
#' @export
#' @examples
#' \dontrun{
#' pd_download("data/mtcars.csv")
#' pd_download("data/mtcars.csv", path = tempfile(fileext = ".csv"))
#' pd_download("data", path = "local-copy-of-data")
#' }
pd_download <- function(file, path = NULL, overwrite = FALSE) {
  file <- as_dribble(file)
  check_single(file, "file")
  path <- path %||% file$name
  check_string(path, "path")

  if (file.exists(path) && !isTRUE(overwrite)) {
    cli::cli_abort(c(
      "Local path {.file {path}} already exists.",
      "i" = "Use {.code overwrite = TRUE} to replace it."
    ))
  }

  downloaded <- download_to_temp(file)
  on.exit(unlink(dirname(downloaded), recursive = TRUE), add = TRUE)

  if (file.exists(path)) {
    unlink(path, recursive = TRUE)
  }
  move_local(downloaded, path)

  pd_inform(c(
    "v" = "Downloaded {.file {display_path(file)}} to {.file {path}}."
  ))
  out <- file
  out$local_path <- normalizePath(path)
  invisible(out)
}

#' Read the content of a Proton Drive file
#'
#' @description
#' Downloads a file and returns its content directly, without leaving a
#' copy on disk. These are the analogues of
#' [googledrive::drive_read_string()] and [googledrive::drive_read_raw()].
#'
#' @inheritParams pd_download
#' @param encoding Encoding of the file's text, passed to [iconv()].
#'
#' @return
#' * `pd_read_string()`: a single string.
#' * `pd_read_raw()`: a raw vector.
#' @export
#' @examples
#' \dontrun{
#' pd_read_string("data/mtcars.csv") |> read.csv(text = _)
#' pd_read_raw("images/logo.png")
#' }
pd_read_string <- function(file, encoding = "UTF-8") {
  raw <- pd_read_raw(file)
  out <- rawToChar(raw)
  if (!identical(toupper(encoding), "UTF-8")) {
    out <- iconv(out, from = encoding, to = "UTF-8")
  }
  Encoding(out) <- "UTF-8"
  out
}

#' @rdname pd_read_string
#' @export
pd_read_raw <- function(file) {
  file <- as_dribble(file)
  check_single(file, "file")
  type <- node_field(file, "type")
  if (!is.na(type) && !type %in% c("file", "photo")) {
    cli::cli_abort("Can only read files, not a {type}.")
  }
  downloaded <- download_to_temp(file)
  on.exit(unlink(dirname(downloaded), recursive = TRUE), add = TRUE)
  readBin(downloaded, what = "raw", n = file.size(downloaded))
}

# Download into a fresh temporary folder and return the single item the CLI
# wrote. Downloading into an empty folder sidesteps the CLI's local conflict
# handling entirely; the caller then places the result where it belongs.
download_to_temp <- function(file, call = rlang::caller_env()) {
  dir <- tempfile("protondrive-")
  dir.create(dir)
  summary <- tryCatch(
    pd_cli("filesystem", "download", c(pd_address(file, call = call), dir)),
    error = function(e) {
      unlink(dir, recursive = TRUE)
      rlang::cnd_signal(e)
    }
  )

  written <- list.files(dir, full.names = TRUE, all.files = TRUE, no.. = TRUE)
  if (length(written) != 1) {
    unlink(dir, recursive = TRUE)
    why <- if (transfer_count(summary, "skippedItems") > 0) {
      "It was skipped by the CLI. Proton Docs and Sheets can't be downloaded."
    } else {
      "The CLI did not write the expected file."
    }
    cli::cli_abort(
      c("Failed to download {.file {display_path(file)}}.", "x" = why),
      class = "protondrive_error",
      call = call
    )
  }
  written
}

move_local <- function(from, to) {
  if (file.rename(from, to)) {
    return(invisible(to))
  }
  # `file.rename()` can't cross file systems; fall back to copying.
  if (dir.exists(from)) {
    dir.create(to, recursive = TRUE)
    ok <- all(file.copy(
      list.files(from, full.names = TRUE, all.files = TRUE, no.. = TRUE),
      to,
      recursive = TRUE,
      copy.date = TRUE
    ))
  } else {
    ok <- file.copy(from, to, copy.date = TRUE)
  }
  if (!ok) {
    cli::cli_abort("Failed to write {.file {to}}.")
  }
  invisible(to)
}
