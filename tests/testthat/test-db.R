test_that("helpers reject things that are not connections", {
  expect_error(omicidx_tables("latest"), "must be a connection")
  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con))
  expect_error(omicidx_release(con), "not opened by omicidx_connect")
})

skip_on_cran()
skip_if_offline()

db <- omicidx_db()
con <- attr(db, "con")

test_that("omicidx_tables lists the sradb and geometadb marts", {
  tables <- omicidx_tables(con)
  expect_named(tables, c("schema", "table", "type"))
  expect_true(all(c("study", "sra") %in% tables$table[tables$schema == "sradb"]))
  expect_true(all(c("gse", "gsm") %in% tables$table[tables$schema == "geometadb"]))
})

test_that("omicidx_describe returns column names and types", {
  cols <- omicidx_describe(db, "sradb.study")
  expect_named(cols, c("column_name", "column_type", "null"))
  expect_true("study_accession" %in% cols$column_name)
  expect_error(omicidx_describe(con, "sradb.no_such_table"))
})

test_that("omicidx_db nests lazy tables by schema", {
  expect_s3_class(db, "omicidx_db")
  expect_true(all(c("sradb", "geometadb") %in% names(db)))
  expect_true("study" %in% names(db$sradb))
  expect_s3_class(db$sradb$study, "tbl_lazy")
  out <- db$sradb$study |> dplyr::filter(study_accession == "SRP000001") |>
    dplyr::collect()
  expect_equal(nrow(out), 1L)
  expect_output(print(db), "OmicIDX release latest \\(published")
  expect_output(print(db), "sradb")
  expect_output(print(db$sradb), "study")
})

DBI::dbDisconnect(con)
