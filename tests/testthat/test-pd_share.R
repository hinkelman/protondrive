sharing_info <- function(url = NULL) {
  info <- list(
    protonInvitations = list(list(
      uid = "i1", invitationTime = "2026-09-03T00:00:00.000Z",
      addedByEmail = list(ok = TRUE, value = "me@proton.me"),
      inviteeEmail = "bo@proton.me", role = "viewer"
    )),
    nonProtonInvitations = list(),
    members = list(list(
      uid = "m1", invitationTime = "2026-09-01T00:00:00.000Z",
      addedByEmail = list(ok = TRUE, value = "me@proton.me"),
      inviteeEmail = "ana@proton.me", role = "editor"
    )),
    editorsCanShare = FALSE
  )
  if (!is.null(url)) {
    info$urlAccess <- list(uid = "u", url = url, role = "viewer",
                           creationTime = "2026-09-01T00:00:00.000Z",
                           numberOfInitializedDownloads = 0)
  }
  info
}

test_that("pd_share() invites people with a role", {
  log <- local_fake_cli("sharing invite" = sharing_info())
  file <- fake_dribble("a", 1)
  out <- pd_share(file, c("ana@proton.me", "bo@proton.me"), role = "editor",
                  message = "hi", include_name = TRUE)
  args <- log$calls[[1]]
  expect_equal(option_value(args, "user"), c("ana@proton.me", "bo@proton.me"))
  expect_equal(option_value(args, "role"), "editor")
  expect_equal(option_value(args, "message"), "hi")
  expect_true("--include-node-name" %in% args)
  expect_equal(out$email, c("ana@proton.me", "bo@proton.me"))
  expect_equal(out$status, c("member", "invited"))

  expect_error(pd_share(file, "not-an-email"), "email")
  expect_error(pd_share(file, "a@b.c", role = "owner"))
})

test_that("pd_sharing() tidies sharing info, including none", {
  local_fake_cli("sharing status" = sharing_info())
  out <- pd_sharing(fake_dribble("a", 1))
  expect_named(out, c("email", "role", "status", "invited_by", "invitation_time"))
  expect_s3_class(out$invitation_time, "POSIXct")

  local_fake_cli("sharing status" = "null")
  expect_equal(nrow(pd_sharing(fake_dribble("a", 1))), 0)
})

test_that("pd_unshare() removes some or everyone", {
  log <- local_fake_cli("sharing remove" = sharing_info())
  file <- fake_dribble("a", 1)
  pd_unshare(file, "bo@proton.me")
  expect_equal(option_value(log$calls[[1]], "email"), "bo@proton.me")
  pd_unshare(file, everyone = TRUE)
  expect_true("--everyone" %in% log$calls[[2]])
  expect_error(pd_unshare(file), "not both")
  expect_error(pd_unshare(file, "a@b.c", everyone = TRUE), "not both")
})

test_that("pd_share_link() creates links with options", {
  log <- local_fake_cli("sharing set-url" = sharing_info("https://drive.proton.me/urls/X#Y"))
  file <- fake_dribble("a", 1)
  url <- pd_share_link(file, password = "pw", expiration = as.Date("2026-12-31"))
  expect_equal(url, "https://drive.proton.me/urls/X#Y")
  args <- log$calls[[1]]
  expect_equal(option_value(args, "expiration"), "2026-12-31")
  expect_equal(option_value(args, "password"), "pw")
  expect_equal(option_value(args, "role"), "viewer")
})

test_that("pd_link() returns the URL or NA", {
  local_fake_cli("sharing status" = sharing_info("https://x"))
  expect_equal(pd_link(fake_dribble("a", 1)), "https://x")
  local_fake_cli("sharing status" = sharing_info())
  expect_equal(pd_link(fake_dribble("a", 1)), NA_character_)
})

test_that("pd_unshare_link() and pd_leave() call the CLI", {
  log <- local_fake_cli("sharing remove-url" = sharing_info(), "sharing leave" = "")
  pd_unshare_link(fake_dribble("a", 1))
  pd_leave(fake_dribble("a", 1, path = "/shared-with-me/a"))
  expect_equal(log$calls[[1]][1:2], c("sharing", "remove-url"))
  expect_equal(log$calls[[2]][1:2], c("sharing", "leave"))
})

test_that("format_expiration() handles dates and times", {
  expect_null(format_expiration(NULL))
  expect_equal(format_expiration("2026-01-01"), "2026-01-01")
  expect_equal(
    format_expiration(as.POSIXct("2026-01-01 12:00:00", tz = "UTC")),
    "2026-01-01T12:00:00Z"
  )
  expect_error(format_expiration(1), "expiration")
})

test_that("invitations can be listed, accepted, and rejected", {
  log <- local_fake_cli(
    "invitation list" = list(list(
      uid = "drive~abc", invitationTime = "2026-09-01T00:00:00.000Z",
      addedByEmail = list(ok = FALSE, error = list(claimedAuthor = "eve@x.y", error = "bad")),
      inviteeEmail = "me@proton.me", role = "viewer",
      node = list(uid = "n", name = list(ok = TRUE, value = "Plans"), type = "folder")
    )),
    "invitation accept" = "",
    "invitation reject" = ""
  )
  inv <- pd_invitations()
  expect_equal(inv$id, "drive~abc")
  expect_equal(inv$name, "Plans")
  expect_equal(inv$invited_by, "(eve@x.y)")
  pd_accept_invitation(inv$id)
  pd_reject_invitation(inv$id)
  expect_equal(positional(log$calls[[2]]), "drive~abc")
  expect_equal(log$calls[[3]][1:2], c("invitation", "reject"))

  local_fake_cli("invitation list" = list())
  expect_equal(nrow(pd_invitations()), 0)
})

test_that("pd_size() reports folder sizes", {
  local_fake_cli("filesystem size" = list(size = 2048, numberOfDescendants = 3))
  out <- pd_size(fake_dribble("data", 1, type = "folder"))
  expect_equal(out$size, 2048)
  expect_equal(out$n_items, 3L)
})
