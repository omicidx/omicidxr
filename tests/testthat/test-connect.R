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
        "https://huggingface.co/datasets/seandavis/omicidx/resolve/2026-10/"
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
    ua <- DBI::dbGetQuery(
        con, "SELECT current_setting('custom_user_agent') AS ua"
    )$ua
    expect_equal(ua, paste0("omicidxr/", utils::packageVersion("omicidxr")))
    ext_dir <- DBI::dbGetQuery(
        con, "SELECT current_setting('extension_directory') AS d"
    )$d
    cache <- tools::R_user_dir("omicidxr", "cache")
    expect_equal(ext_dir, file.path(cache, "extensions"))
})

test_that("omicidx_release reads the manifest of each kind of release", {
    skip_on_cran()
    skip_if_offline()
    con <- omicidx_connect()
    on.exit(DBI::dbDisconnect(con))
    latest <- omicidx_release(con)
    expect_equal(latest$version, "latest")
    expect_match(latest$publish_date, "^\\d{4}-\\d{2}-\\d{2}$")
    expect_match(latest$transform_sha, "^[0-9a-f]{40}$")
    expect_gt(latest$lake_snapshot_id, 0)
    expect_true("study" %in% latest$tables$table)
    # Read the manifests of a dated and a monthly release without
    # attaching them.
    dated <- read_release(
        con, latest$publish_date,
        omicidx_release_url(latest$publish_date)
    )
    expect_equal(dated$transform_sha, latest$transform_sha)
    monthly <- read_release(con, "2026-10", omicidx_release_url("2026-10"))
    expect_equal(monthly$publish_date, "2026-10-20")
    missing <- read_release(con, "2000-01", omicidx_release_url("2000-01"))
    expect_true(is.na(missing$publish_date))
    expect_null(missing$tables)
})

test_that("omicidx_connect explains an aged-out dated release", {
    skip_on_cran()
    skip_if_offline()
    expect_error(omicidx_connect("2000-01-01"), "monthly release")
    expect_error(omicidx_connect("2000-01"), "not found")
})
