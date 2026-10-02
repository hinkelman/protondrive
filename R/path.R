# Proton Drive paths are virtual and always POSIX. The first segment is a
# section (`/my-files`, `/shared-with-me`, `/trash`, ...). A literal `/` inside
# a name is escaped as `\/`. Mirrors cli/src/cli/paths.ts.

pd_sections <- c(
  "my-files",
  "devices",
  "shared-by-me",
  "shared-with-me",
  "trash",
  "albums",
  "photos",
  "photos-shared-by-me",
  "photos-shared-with-me",
  "photos-trash"
)

drive_sections <- c("my-files", "devices", "shared-with-me")
photo_sections <- c("albums", "photos")
trash_sections <- c("trash", "photos-trash")

# Turn user input into an absolute virtual path. Relative paths and `~` are
# relative to `/my-files`, which plays the role of "My Drive" in googledrive.
normalize_path <- function(x, call = rlang::caller_env()) {
  if (!is.character(x)) {
    cli::cli_abort("{.arg path} must be a character vector.", call = call)
  }
  x[is.na(x) | x %in% c("", "~", "~/")] <- "/my-files"
  x <- sub("^~/", "/my-files/", x)
  relative <- !startsWith(x, "/")
  x[relative] <- paste0("/my-files/", x[relative])
  x <- gsub("/{2,}", "/", x)
  trailing <- nchar(x) > 1 & endsWith(x, "/") & !endsWith(x, "\\/")
  x[trailing] <- substr(x[trailing], 1, nchar(x[trailing]) - 1)

  section <- path_section(x)
  bad <- !is.na(section) & !section %in% pd_sections
  if (any(bad)) {
    cli::cli_abort(
      c(
        "{.val {x[bad]}} {?is/are} not {?a/} valid Proton Drive path{?s}.",
        "i" = "Paths start with one of {.val {paste0('/', pd_sections)}}.",
        "i" = "Relative paths are taken relative to {.val /my-files}."
      ),
      call = call
    )
  }
  x
}

# Split on unescaped `/`.
path_segments <- function(path) {
  marker <- "\u001f"
  lapply(path, function(p) {
    if (is.na(p)) {
      return(NA_character_)
    }
    p <- gsub("\\/", marker, p, fixed = TRUE)
    parts <- strsplit(p, "/", fixed = TRUE)[[1]]
    gsub(marker, "/", parts[-1], fixed = TRUE)
  })
}

path_section <- function(path) {
  vapply(
    path_segments(path),
    function(s) if (length(s) == 0) NA_character_ else s[[1]],
    character(1)
  )
}

path_basename <- function(path) {
  vapply(
    path_segments(path),
    function(s) if (length(s) == 0) "" else s[[length(s)]],
    character(1)
  )
}

path_parent <- function(path) {
  vapply(
    path_segments(path),
    function(s) {
      if (length(s) == 1 && is.na(s)) {
        return(NA_character_)
      }
      paste0("/", paste(escape_name(utils::head(s, -1)), collapse = "/"))
    },
    character(1)
  )
}

escape_name <- function(name) {
  gsub("/", "\\/", name, fixed = TRUE)
}

path_join <- function(parent, name) {
  out <- paste0(sub("/$", "", parent), "/", escape_name(name))
  out[is.na(parent) | is.na(name)] <- NA_character_
  out
}

# The string the CLI should receive for each row of a dribble. Drive and
# photo nodes are addressed by ID when possible, which survives renames and
# moves; trashed nodes and virtual sections can only be addressed by path.
pd_address <- function(x, call = rlang::caller_env()) {
  x <- as_dribble(x, call = call)
  id <- vctrs::vec_data(x$id)
  path <- x$path
  section <- path_section(path)
  valid_id <- is_node_uid(id)

  address <- path
  by_id <- valid_id & !section %in% c(trash_sections, photo_sections,
                                       "photos-shared-by-me",
                                       "photos-shared-with-me")
  address[by_id] <- paste0("/my-files/", id[by_id])
  photo <- valid_id & section %in% photo_sections
  address[photo] <- paste0("/", section[photo], "/", id[photo])

  if (anyNA(address)) {
    cli::cli_abort(
      "Can't determine how to address {.val {x$name[is.na(address)]}} on Proton Drive.",
      call = call
    )
  }
  address
}

# A human-readable location for messages.
display_path <- function(x) {
  ifelse(is.na(x$path), x$name, x$path)
}
