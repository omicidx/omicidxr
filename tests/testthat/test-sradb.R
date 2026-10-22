test_that("accession_type recognises SRA, GEO, BioSample and BioProject", {
    expect_equal(
        accession_type(c(
            "SRP000001", "ERS123", "DRX9", "SRR1", "SAMN17187141",
            "SAMEA123", "PRJNA688734", "PRJEB1", "GSE1", "GSM1", "GPL570"
        )),
        c(
            "study", "sample", "experiment", "run", "biosample", "biosample",
            "bioproject", "bioproject", "gse", "gsm", "gpl"
        )
    )
    expect_error(accession_type("foo"), "Unrecognised")
    expect_error(accession_type("SRP1; DROP TABLE x"), "Unrecognised")
})

test_that("check_accessions upper-cases, de-duplicates and checks types", {
    expect_equal(check_accessions(c("gse1", "GSE1")), "GSE1")
    expect_error(check_accessions("GSM1", "gse"), "Expected gse")
})

test_that("text_search validates its arguments before querying", {
    con <- DBI::dbConnect(duckdb::duckdb())
    on.exit(DBI::dbDisconnect(con))
    expect_error(sra_search(con, c("a", "b")))
    expect_error(sra_search(con, "a", limit = NA))
})

skip_on_cran()
skip_if_offline()

con <- omicidx_connect()

test_that("sra_convert maps a study to its samples, experiments and runs", {
    out <- sra_convert(con, "SRP000001")
    expect_named(out, c("study", "sample", "experiment", "run"))
    expect_true(all(out$study == "SRP000001"))
    expect_true("SRR000001" %in% out$run)
})

test_that("sra_convert crosses SRA and GEO in both directions", {
    out <- sra_convert(con, "GSM4996084", c("run", "gse"))
    expect_equal(unique(out$gse), "GSE164073")
    expect_true(all(startsWith(out$run, "SRR")))
    back <- sra_convert(con, out$run[1], "gsm")
    expect_equal(back$gsm, "GSM4996084")
})

test_that("geo_convert maps a series to samples and platforms", {
    out <- geo_convert(con, in_acc = "GSE164073")
    expect_named(out, c("gse", "gsm", "gpl"))
    expect_equal(nrow(out), 18L)
    expect_equal(unique(out$gpl), "GPL18573")
})

test_that("sra_runs returns download fields for a study and a GSE", {
    runs <- sra_runs(con, "SRP000001")
    fields <- c("run_accession", "library_layout", "spots")
    expect_true(all(fields %in% names(runs)))
    expect_true(all(runs$study_accession == "SRP000001"))
    expect_true(all(sra_runs(con, "GSE164073")$study_accession == "SRP299835"))
    expect_equal(nrow(sra_runs(con, "GSE10000")), 0L)
})

test_that("geo_samples joins samples to their platform", {
    out <- geo_samples(con, "GSE164073")
    expect_equal(nrow(out), 18L)
    fields <- c("gsm", "gpl", "platform_title", "sra_experiment")
    expect_true(all(fields %in% names(out)))
})

test_that("geo_characteristics returns one row per tag/value pair", {
    out <- geo_characteristics(con, "GSM250925")
    expect_named(out, c("gsm", "channel", "tag", "value"))
    expect_equal(out$value[out$tag == "tissue"], "aorta")
})

test_that("sra_search and geo_search match titles case-insensitively", {
    studies <- sra_search(con, "SINGLE CELL%glioma", limit = 3)
    expect_lte(nrow(studies), 3L)
    text <- paste(studies$study_title, studies$study_abstract)
    expect_true(all(grepl("single cell", text, ignore.case = TRUE)))
    series <- geo_search(con, "glioblastoma", limit = 3)
    expect_equal(nrow(series), 3L)
    expect_equal(nrow(sra_search(con, "'; DROP TABLE x; --", limit = 3)), 0L)
})

DBI::dbDisconnect(con)
