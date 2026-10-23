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
#'   and are the version to cite.
#'
#' Query `"latest"` and dated builds in place: they are served without
#' rate limits. Treat monthly releases as the archive: copy one with
#' `omicidx_download("YYYY-MM", path)` and query the local file.
#' Connecting to a monthly release in place works, but takes about 30
#' seconds (DuckDB inspects every Parquet file while it creates the
#' views) and runs into HuggingFace's rate limits.
#'
#' @section HuggingFace rate limits:
#' HuggingFace allows 3000 anonymous requests per 5 minutes per IP
#' address, and connecting to a monthly release or running one query can
#' make hundreds, so heavy use, or a shared IP address, fails with HTTP
#' 429 (Too Many Requests) until the window resets. To avoid it:
#' * Download the release with
#'   [omicidx_download()], which waits
#'   out the limit, and query the local copy.
#' * Set the environment variable `HF_TOKEN` to a HuggingFace access
#'   token, which raises the limit to that of a signed-in user.
#' * Within 30 days of a monthly release, connect to the dated build it
#'   was published from (`omicidx_release(con)$publish_date`), which
#'   holds the same data.
#'
#' @section Timeouts:
#' Each HTTP request times out after 30 seconds and is retried up to 4
#' times, after waits of 0, 1, 4 and 16 seconds, which also rides out a
#' brief HTTP 429. If connecting still fails, `omicidx_connect()` stops
#' with an error naming the release URL.
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
        autoload_known_extensions = "true",
        # Bound every request, including views.sql and manifest.json, so a
        # stalled connection fails instead of hanging; see the Timeouts
        # section.
        http_timeout = "30",
        http_retries = "4",
        http_retry_wait_ms = "1000"
    ))
    con <- DBI::dbConnect(drv)
    ok <- FALSE
    on.exit(if (!ok) DBI::dbDisconnect(con), add = TRUE)

    tryCatch(
        attach_release(con, version, release_url),
        error = function(e) stop_release_error(version, release_url, e)
    )

    attr(con, "omicidx_release") <- read_release(con, version, release_url)
    ok <- TRUE
    con
}

# Monthly releases ship views.sql; nightly builds ship omicidx.duckdb.
attach_release <- function(con, version, release_url) {
    if (grepl("^\\d{4}-\\d{2}$", version)) {
        hf_token <- Sys.getenv("HF_TOKEN")
        if (nzchar(hf_token)) {
            DBI::dbExecute(con, paste0(
                "CREATE SECRET omicidx_hf (TYPE huggingface, TOKEN ",
                DBI::dbQuoteString(con, hf_token), ")"
            ))
        }
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

# Re-raise an error reading a release with its URL and what to do next.
stop_release_error <- function(version, url, e) {
    msg <- conditionMessage(e)
    hint <- if (grepl("429", msg)) {
        paste(
            "HuggingFace is rate limiting requests (HTTP 429). Wait 5",
            "minutes and try again, set HF_TOKEN to a HuggingFace access",
            "token for a higher limit, or see ?omicidx_connect."
        )
    } else if (grepl("404|does not exist", msg) &&
        grepl("^\\d{4}-\\d{2}-\\d{2}$", version)) {
        paste(
            "Dated releases are kept for 30 days. For older or citable",
            "data, use a monthly release, e.g.",
            "omicidx_download(\"YYYY-MM\", path)."
        )
    }
    stop(
        "Could not read OmicIDX release '", version, "' at ", url, ":\n",
        msg, if (!is.null(hint)) c("\n", hint),
        call. = FALSE
    )
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
#' Copies the tables of a release into a new DuckDB database file, so they
#' can be queried offline and at local-disk speed. The copy is checked
#' against the row counts in the release's `manifest.json`. This is the R
#' counterpart of the `restore.sql` published with each nightly build.
#'
#' A full release is large: about 75 GB of Parquet, which becomes a DuckDB
#' file about 5 times that size (400 GB for `"2026-10"`), and took about
#' an hour to copy. Pass `tables` to copy only what you need,
#' such as the `"sradb"` or `"geometadb"` marts. Before copying,
#' `omicidx_download()` reports the size of the Parquet it will read.
#'
#' Tables are copied one at a time. Copying a monthly release makes tens
#' of thousands of requests to HuggingFace, more than its rate limit
#' allows in 5 minutes (see
#' [omicidx_connect()]), so each request is
#' retried for up to 6 minutes and the copy pauses while the limit
#' resets. Setting `HF_TOKEN` raises the limit.
#'
#' @inheritParams omicidx_connect
#' @param path character(1). The DuckDB file to create. It must not exist.
#' @param tables character. The tables to copy, as `"schema.table"` (for
#'   example `"sradb.study"` or `"main.sra_runs"`) or whole schemas (for
#'   example `"sradb"`). `NULL` (default) copies every table.
#'   [omicidx_tables()] lists them.
#'
#' @return `path`, invisibly. Open it with
#'   `DBI::dbConnect(duckdb::duckdb(), path)`; tables keep their names,
#'   for example `sradb.study`.
#'
#' @examples
#' path <- omicidx_download(
#'     "latest", tempfile(fileext = ".duckdb"), tables = "geometadb.gpl"
#' )
#' con <- DBI::dbConnect(duckdb::duckdb(), path, read_only = TRUE)
#' DBI::dbGetQuery(con, "SELECT count(*) AS n FROM geometadb.gpl")
#' DBI::dbDisconnect(con)
#'
#' @export
omicidx_download <- function(version = "latest", path, tables = NULL) {
    stopifnot(is.character(path), length(path) == 1L, !is.na(path))
    stopifnot(is.null(tables) || (is.character(tables) && !anyNA(tables)))
    if (file.exists(path)) {
        stop("`path` already exists: ", path, call. = FALSE)
    }
    con <- omicidx_connect(version)
    on.exit(DBI::dbDisconnect(con), add = TRUE)
    # Waits of 0, 1, 4, 16, 64 and 256 s outlast HuggingFace's 5-minute
    # rate-limit window.
    DBI::dbExecute(con, "SET http_retries = 6")
    selected <- select_tables(omicidx_tables(con), tables)
    message(
        "Copying ", nrow(selected), " tables, about ",
        format(parquet_bytes(con, selected) / 1e9, digits = 2),
        " GB of Parquet, to ", path,
        ". The DuckDB file can be several times larger."
    )
    url <- omicidx_release(con)$url
    tryCatch(
        copy_release(con, path, selected),
        error = function(e) stop_release_error(version, url, e)
    )
    invisible(path)
}

# The rows of `all` (from omicidx_tables()) named in `tables`, as
# "schema.table" or a whole schema.
select_tables <- function(all, tables) {
    if (is.null(tables)) {
        return(all)
    }
    full <- paste(all$schema, all$table, sep = ".")
    unknown <- setdiff(tables, c(full, all$schema))
    if (length(unknown)) {
        stop(
            "Not tables or schemas of this release: ",
            paste(unknown, collapse = ", "), ". See omicidx_tables().",
            call. = FALSE
        )
    }
    all[full %in% tables | all$schema %in% tables, ]
}

# Compressed size, in bytes, of the Parquet files behind the views in
# `tables`, read from the files' footers; NA if they cannot be read.
parquet_bytes <- function(con, tables) {
    views <- DBI::dbGetQuery(con, "
    SELECT schema_name AS schema, view_name AS table,
        regexp_extract(sql, 'read_parquet\\(''([^'']+)''', 1) AS file
    FROM duckdb_views() WHERE NOT internal")
    files <- merge(tables, views)$file
    files <- files[nzchar(files)]
    if (!length(files)) {
        return(0)
    }
    tryCatch(DBI::dbGetQuery(con, paste0(
        "SELECT sum(total_compressed_size)::DOUBLE AS n ",
        "FROM parquet_metadata([",
        paste(DBI::dbQuoteString(con, files), collapse = ", "), "])"
    ))$n, error = function(e) NA_real_)
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
