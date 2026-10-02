# A fake `proton-drive` CLI for tests. Responders are keyed by
# "<group> <command>" and receive the positional arguments (those after
# `--`) and the full argv. They return either a value to be serialised as the
# command's JSON output, or a complete result from `cli_ok()`/`cli_fail()`.
local_fake_cli <- function(..., .env = parent.frame()) {
  responders <- list(...)
  log <- new.env(parent = emptyenv())
  log$calls <- list()

  fake <- function(args, echo = FALSE) {
    log$calls[[length(log$calls) + 1]] <- args
    key <- paste(args[[1]], args[[2]])
    responder <- responders[[key]]
    if (is.null(responder)) {
      stop("Unexpected CLI call: ", paste(args, collapse = " "), call. = FALSE)
    }
    out <- if (is.function(responder)) responder(positional(args), args) else responder
    if (is.list(out) && setequal(names(out), c("status", "stdout", "stderr"))) {
      return(out)
    }
    cli_ok(out)
  }

  local_mocked_bindings(
    pd_run_cli = fake,
    pd_cli_path = function() "/fake/proton-drive",
    .env = .env
  )
  log
}

cli_ok <- function(x = NULL) {
  stdout <- if (is.character(x)) x else if (is.null(x)) "" else to_json(x)
  list(status = 0L, stdout = stdout, stderr = "")
}

cli_fail <- function(message, stdout = "") {
  list(status = 1L, stdout = stdout, stderr = paste0(message, "\n"))
}

to_json <- function(x) {
  as.character(jsonlite::toJSON(x, auto_unbox = TRUE, null = "null", digits = NA))
}

positional <- function(args) {
  i <- match("--", args)
  if (is.na(i)) character() else args[-seq_len(i)]
}

option_value <- function(args, flag) {
  i <- which(args == paste0("--", flag))
  if (length(i) == 0) NULL else args[i + 1]
}

# UIDs in the format the CLI recognises: two 22-character parts.
fake_uid <- function(i, volume = 1) {
  sprintf("vol%019d~node%018d", volume, i)
}

fake_node <- function(name, i, type = "file", parent = 0, size = 100,
                      media_type = if (type == "file") "text/plain",
                      shared = FALSE, volume = 1) {
  node <- list(
    uid = fake_uid(i, volume),
    parentUid = fake_uid(parent, volume),
    name = list(ok = TRUE, value = name),
    keyAuthor = list(ok = TRUE, value = "me@proton.me"),
    nameAuthor = list(ok = TRUE, value = "me@proton.me"),
    directRole = "admin",
    ownedBy = list(email = "me@proton.me"),
    type = type,
    isShared = shared,
    isSharedByUrl = FALSE,
    creationTime = "2026-09-01T10:00:00.000Z",
    modificationTime = "2026-09-02T11:30:00.000Z",
    totalStorageSize = size + 50,
    treeEventScopeId = "scope"
  )
  if (!is.null(media_type)) {
    node$mediaType <- media_type
  }
  if (type == "file") {
    node$activeRevision <- list(
      uid = paste0("rev", i),
      state = "active",
      creationTime = "2026-09-02T11:30:00.000Z",
      contentAuthor = list(ok = TRUE, value = "me@proton.me"),
      storageSize = size + 50,
      isImported = FALSE,
      claimedSize = size,
      claimedModificationTime = "2026-08-30T09:00:00.000Z",
      claimedDigests = list(sha1 = "da39a3ee5e6b4b0d3255bfef95601890afd80709", sha1Verified = TRUE)
    )
  }
  node
}

# The CLI prints bulk results as a JSON array, one object per node.
node_results <- function(uids, ok = TRUE) {
  lapply(uids, function(u) list(uid = u, ok = ok))
}

fake_dribble <- function(name, i, path = paste0("/my-files/", name), ...) {
  dribble_from_nodes(list(fake_node(name, i, ...)), path = path)
}
