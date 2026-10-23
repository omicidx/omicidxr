#' Connect to an OmicIDX release
#'
#' Opens an in-memory DuckDB database and makes an OmicIDX release
#' available in it. Nothing is downloaded up front: queries read the
#' remote Parquet files over HTTPS, fetching only the columns and row
#' groups they need.
#'
#' After connecting, tables are referenced as `schema.table`, for
#' example `sradb.study` or `geometadb.gsm`. Use
#' [omicidx_tables()] to list them and
#' [omicidx_db()] for tab-completable `dplyr` tables.
#'
#' @section Versions:
#' * `"latest"`: the nightly build at
#'   `https://omicidx.cancerdatasci.org/data/latest/`.
#' * `"YYYY-MM-DD"`: a dated nightly build, kept for 30 days.
#' * `"YYYY-MM"`: a monthly release on HuggingFace
#'   (`seandavis/omicidx@YYYY-MM`). Monthly releases are kept long term
#'   and are the version to cite. Connecting takes longer (about 30
#'   seconds) because DuckDB inspects every Parquet file while it
#'   creates the views. HuggingFace limits anonymous requests (3000 per
#'   5 minutes per IP address) and one query can make hundreds, so heavy
#'   use can fail with HTTP 429 until the window resets.
#'
#' Requests carry the User-Agent `omicidxr/<package version>`. DuckDB
#' extensions (`httpfs`, `json`) are downloaded once and cached in
#' `tools::R_user_dir("omicidxr", "cache")`. The connection neither uses
#' `~/.duckdb` nor reads DuckDB secrets persisted there.
#'
#' @param version character(1). `"latest"` (default), a date
#'   `"YYYY-MM-DD"` or a month `"YYYY-MM"`. See the Versions section.
#'
#' @return A DuckDB [DBI::DBIConnection-class]. Close it with
#'   [DBI::dbDisconnect()].
#'   [omicidx_release()] tells which release it is
#'   connected to.
#'
#' @examples
#' con <- omicidx_connect()
#' DBI::dbGetQuery(con, "SELECT count(*) AS n FROM sradb.study")
#' DBI::dbDisconnect(con)
#'
#' @export
omicidx_connect <- function(version = "latest") {
    release_url <- omicidx_release_url(version)
    drv <- duckdb::duckdb(config = list(
        custom_user_agent = paste0(
            "omicidxr/", utils::packageVersion("omicidxr")
        ),
        allow_persistent_secrets = "false",
        # Setting both directories keeps duckdb away from, and quiet about,
        # ~/.duckdb. Extensions persist so httpfs downloads once per user.
        extension_directory = file.path(
            tools::R_user_dir("omicidxr", "cache"), "extensions"
        ),
        secret_directory = file.path(tempdir(), "omicidxr-secrets"),
        autoinstall_known_extensions = "true",
        autoload_known_extensions = "true"
    ))
    con <- DBI::dbConnect(drv)
    ok <- FALSE
    on.exit(if (!ok) DBI::dbDisconnect(con), add = TRUE)

    tryCatch(
        attach_release(con, version, release_url),
        error = function(e) {
            if (grepl("404|does not exist", conditionMessage(e))) {
                stop(
                    "OmicIDX release '", version, "' was not found at ",
                    release_url, ".\n",
                    "Dated releases are kept for 30 days. For older or ",
                    "citable data, use a monthly release, ",
                    "e.g. omicidx_connect(\"YYYY-MM\").",
                    call. = FALSE
                )
            }
            stop(e)
        }
    )

    attr(con, "omicidx_release") <- read_release(con, version, release_url)
    ok <- TRUE
    con
}

# Monthly releases ship views.sql; nightly builds ship omicidx.duckdb.
attach_release <- function(con, version, release_url) {
    if (grepl("^\\d{4}-\\d{2}$", version)) {
        views_sql <- DBI::dbGetQuery(
            con, "SELECT content FROM read_text(?)",
            params = list(paste0(release_url, "views.sql"))
        )$content
        DBI::dbExecute(con, views_sql)
    } else {
        db_url <- paste0(release_url, "omicidx.duckdb")
        DBI::dbExecute(con, paste0(
            "ATTACH ", DBI::dbQuoteString(con, db_url),
            " AS omicidx (READ_ONLY); USE omicidx;"
        ))
    }
}

#' Which OmicIDX release a connection is on
#'
#' The release a connection from
#' [omicidx_connect()] points at, with the provenance
#' recorded in the release's `manifest.json`. Cite `version`
#' and `publish_date`; `transform_sha` and `lake_snapshot_id`
#' identify exactly how and from what the release was built.
#'
#' @inheritParams omicidx_tables
#'
#' @return A list with `version` (as passed to
#'   [omicidx_connect()]),
#'   `url` (the release folder), and from `manifest.json`:
#'   `publish_date`, `transform_sha` (the commit of the OmicIDX
#'   transform code), `lake_snapshot_id` (the source data snapshot) and
#'   `tables` (a tibble of `schema`, `table` and
#'   `row_count`). The manifest fields are `NA` (`tables` is
#'   `NULL`) if `manifest.json` could not be read.
#'
#' @examples
#' con <- omicidx_connect()
#' omicidx_release(con)$publish_date
#' DBI::dbDisconnect(con)
#'
#' @export
omicidx_release <- function(con) {
    release <- attr(omicidx_con(con), "omicidx_release")
    if (is.null(release)) {
        stop("`con` was not opened by omicidx_connect().", call. = FALSE)
    }
    release
}

#' Download an OmicIDX release into a local DuckDB file
#'
#' Copies every table of a release into a new DuckDB database file, so it
#' can be queried offline and at local-disk speed. The copy is checked
#' against the row counts in the release's `manifest.json`. This is the R
#' counterpart of the `restore.sql` published with each nightly build.
#'
#' A full release is large (tens of GB) and takes a while to copy.
#'
#' @inheritParams omicidx_connect
#' @param path character(1). The DuckDB file to create. It must not exist.
#'
#' @return `path`, invisibly. Open it with
#'   `DBI::dbConnect(duckdb::duckdb(), path)`; tables keep their names,
#'   for example `sradb.study`.
#'
#' @examples
#' \dontrun{
#' path <- omicidx_download("2026-10", "omicidx-2026-10.duckdb")
#' con <- DBI::dbConnect(duckdb::duckdb(), path, read_only = TRUE)
#' DBI::dbGetQuery(con, "SELECT count(*) AS n FROM sradb.study")
#' DBI::dbDisconnect(con)
#' }
#'
#' @export
omicidx_download <- function(version = "latest", path) {
    stopifnot(is.character(path), length(path) == 1L, !is.na(path))
    if (file.exists(path)) {
        stop("`path` already exists: ", path, call. = FALSE)
    }
    con <- omicidx_connect(version)
    on.exit(DBI::dbDisconnect(con), add = TRUE)
    copy_release(con, path)
    invisible(path)
}

# Copy `tables` (from omicidx_tables()) of a connected release into a new
# DuckDB file at `path`, then check row counts against the manifest. The file
# is removed if anything fails.
copy_release <- function(con, path, tables = omicidx_tables(con)) {
    manifest <- omicidx_release(con)$tables
    DBI::dbExecute(con, paste0(
        "ATTACH ", DBI::dbQuoteString(con, path), " AS omicidx_local"
    ))
    ok <- FALSE
    on.exit({
        DBI::dbExecute(con, "DETACH omicidx_local")
        if (!ok) unlink(path)
    }, add = TRUE)
    for (schema in setdiff(unique(tables$schema), "main")) {
        DBI::dbExecute(con, paste0(
            "CREATE SCHEMA omicidx_local.", DBI::dbQuoteIdentifier(con, schema)
        ))
    }
    for (i in seq_len(nrow(tables))) {
        name <- paste(
            DBI::dbQuoteIdentifier(con, c(tables$schema[i], tables$table[i])),
            collapse = "."
        )
        message("Copying ", tables$schema[i], ".", tables$table[i])
        DBI::dbExecute(con, paste0(
            "CREATE TABLE omicidx_local.", name, " AS SELECT * FROM ", name
        ))
    }
    check_row_counts(con, tables, manifest)
    ok <- TRUE
    invisible(path)
}

check_row_counts <- function(con, tables, manifest) {
    if (is.null(manifest)) {
        warning("manifest.json could not be read; row counts not checked.",
            call. = FALSE
        )
        return(invisible())
    }
    expected <- merge(tables, manifest, by = c("schema", "table"))
    local_n <- vapply(seq_len(nrow(expected)), function(i) {
        name <- paste(DBI::dbQuoteIdentifier(
            con, c("omicidx_local", expected$schema[i], expected$table[i])
        ), collapse = ".")
        as.numeric(DBI::dbGetQuery(
            con, paste("SELECT count(*) AS n FROM", name)
        )$n)
    }, numeric(1))
    bad <- local_n != expected$row_count
    if (any(bad)) {
        stop("Row counts differ from manifest.json: ",
            paste0(expected$schema[bad], ".", expected$table[bad],
                collapse = ", "
            ),
            call. = FALSE
        )
    }
}

# The release's manifest.json describes the data but is not needed to query
# it, so an unreadable manifest leaves NA fields instead of failing.
read_release <- function(con, version, url) {
    release <- list(
        version = version, url = url, publish_date = NA_character_,
        transform_sha = NA_character_, lake_snapshot_id = NA_real_,
        tables = NULL
    )
    m <- tryCatch(DBI::dbGetQuery(con, "
    SELECT publish_date::VARCHAR AS publish_date, transform_sha,
        lake_snapshot_id, unnest(tables, recursive := true)
    FROM read_json(?)", params = list(paste0(url, "manifest.json"))),
        error = function(e) NULL
    )
    if (is.null(m) || nrow(m) == 0L) {
        return(release)
    }
    utils::modifyList(release, list(
        publish_date = m$publish_date[[1]],
        transform_sha = m$transform_sha[[1]],
        lake_snapshot_id = m$lake_snapshot_id[[1]],
        tables = tibble::as_tibble(m[c("schema", "table", "row_count")])
    ))
}

# Base URL of a release folder; it holds omicidx.duckdb (nightly builds) or
# views.sql (monthly releases), plus manifest.json.
omicidx_release_url <- function(version) {
    stopifnot(is.character(version), length(version) == 1L, !is.na(version))
    if (version == "latest") {
        return("https://omicidx.cancerdatasci.org/data/latest/")
    }
    if (grepl("^\\d{4}-\\d{2}-\\d{2}$", version)) {
        return(sprintf("https://omicidx.cancerdatasci.org/data/v%s/", version))
    }
    if (grepl("^\\d{4}-\\d{2}$", version)) {
        return(sprintf(
            "https://huggingface.co/datasets/seandavis/omicidx/resolve/%s/",
            version
        ))
    }
    stop(
        "`version` must be \"latest\", a date \"YYYY-MM-DD\" or ",
        "a month \"YYYY-MM\", ",
        "not '", version, "'.",
        call. = FALSE
    )
}
