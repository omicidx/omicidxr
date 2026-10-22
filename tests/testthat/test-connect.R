test_that("omicidx_release_url maps versions to release folders", {
  expect_equal(
    omicidx_release_url("latest"),
    "https://omicidx.cancerdatasci.org/data/latest/"
  )
  expect_equal(
    omicidx_release_url("2026-10-20"),
    "https://omicidx.cancerdatasci.org/data/v2026-10-20/"
  )
  expect_equal(
    omicidx_release_url("2026-10"),
    "https://huggingface.co/datasets/omicidx/omicidx/resolve/2026-10/"
  )
  expect_error(omicidx_release_url("2026"), "must be")
  expect_error(omicidx_release_url("v2026-10-20"), "must be")
})

test_that("omicidx_connect attaches the latest release", {
  skip_on_cran()
  skip_if_offline()
  con <- omicidx_connect()
  on.exit(DBI::dbDisconnect(con))
  n <- DBI::dbGetQuery(con, "SELECT count(*) AS n FROM sradb.study")$n
  expect_gt(n, 0)
  ua <- DBI::dbGetQuery(con, "SELECT current_setting('custom_user_agent') AS ua")$ua
  expect_equal(ua, paste0("omicidxr/", utils::packageVersion("omicidxr")))
})

test_that("omicidx_connect explains an aged-out dated release", {
  skip_on_cran()
  skip_if_offline()
  expect_error(omicidx_connect("2000-01-01"), "monthly release")
  expect_error(omicidx_connect("2000-01"), "not found")
})
