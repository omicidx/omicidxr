# An offline stand-in for a connected release: views over local Parquet plus
# the manifest row counts omicidx_release() returns.
fake_release <- function(dir, manifest_n = 3) {
    con <- DBI::dbConnect(duckdb::duckdb())
    DBI::dbExecute(con, "CREATE SCHEMA sradb")
    for (name in c("sra_runs", "sradb.study")) {
        file <- file.path(dir, paste0(name, ".parquet"))
        DBI::dbExecute(con, sprintf(
            "COPY (SELECT range AS id FROM range(3)) TO '%s' (FORMAT PARQUET)",
            file
        ))
        DBI::dbExecute(con, sprintf(
            "CREATE VIEW %s AS SELECT * FROM read_parquet('%s')", name, file
        ))
    }
    attr(con, "omicidx_release") <- list(tables = tibble::tibble(
        schema = c("main", "sradb"), table = c("sra_runs", "study"),
        row_count = c(3, manifest_n)
    ))
    con
}

test_that("copy_release materializes every table and checks the manifest", {
    dir <- tempfile()
    dir.create(dir)
    con <- fake_release(dir)
    on.exit(DBI::dbDisconnect(con))
    path <- file.path(dir, "local.duckdb")
    expect_message(copy_release(con, path), "Copying sradb.study")

    local <- DBI::dbConnect(duckdb::duckdb(), path, read_only = TRUE)
    on.exit(DBI::dbDisconnect(local), add = TRUE)
    expect_equal(
        DBI::dbGetQuery(local, "SELECT count(*) AS n FROM sradb.study")$n, 3
    )
    expect_equal(unique(omicidx_tables(local)$type), "BASE TABLE")
})

test_that("copy_release fails and removes the file on a row-count mismatch", {
    dir <- tempfile()
    dir.create(dir)
    con <- fake_release(dir, manifest_n = 4)
    on.exit(DBI::dbDisconnect(con))
    path <- file.path(dir, "local.duckdb")
    expect_error(
        suppressMessages(copy_release(con, path)),
        "differ from manifest.json: sradb.study"
    )
    expect_false(file.exists(path))
})

test_that("omicidx_download refuses to overwrite a file", {
    path <- tempfile()
    file.create(path)
    expect_error(omicidx_download("latest", path), "already exists")
})

test_that("copy_release copies tables of the latest release", {
    skip_on_cran()
    skip_if_offline()
    con <- omicidx_connect()
    on.exit(DBI::dbDisconnect(con))
    path <- tempfile(fileext = ".duckdb")
    small <- omicidx_tables(con)
    small <- small[small$table %in% c("geo_platforms", "gpl"), ]
    suppressMessages(copy_release(con, path, small))
    local <- DBI::dbConnect(duckdb::duckdb(), path, read_only = TRUE)
    on.exit(DBI::dbDisconnect(local), add = TRUE)
    n <- DBI::dbGetQuery(local, "SELECT count(*) AS n FROM geometadb.gpl")$n
    expect_gt(n, 0)
})
