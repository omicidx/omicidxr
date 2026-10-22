#' Connect to an OmicIDX release
#'
#' Opens an in-memory DuckDB database and makes an OmicIDX release
#' available in it. Nothing is downloaded up front: queries read the
#' remote Parquet files over HTTPS, fetching only the columns and row
#' groups they need.
#'
#' After connecting, tables are referenced as `schema.table`, for
#' example `sradb.study` or `geometadb.gsm`. Use [omicidx_tables()] to
#' list them and [omicidx_db()] for tab-completable `dplyr` tables.
#'
#' @section Versions:
#' * `"latest"`: the nightly build at
#'   `https://omicidx.cancerdatasci.org/data/latest/`.
#' * `"YYYY-MM-DD"`: a dated nightly build, kept for 30 days.
#' * `"YYYY-MM"`: a monthly release on HuggingFace
#'   (`omicidx/omicidx@YYYY-MM`). Monthly releases are kept long term
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
#'   [DBI::dbDisconnect()]. [omicidx_release()] tells which release it
#'   is connected to.
#'
#' @examples
#' \donttest{
#' con <- omicidx_connect()
#' DBI::dbGetQuery(con, "SELECT count(*) AS n FROM sradb.study")
#' DBI::dbDisconnect(con)
#' }
#'
#' @export
omicidx_connect <- function(version = "latest") {
  release_url <- omicidx_release_url(version)
  drv <- duckdb::duckdb(config = list(
    custom_user_agent = paste0("omicidxr/", utils::packageVersion("omicidxr")),
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
    if (grepl("^\\d{4}-\\d{2}$", version)) {
      views_sql <- DBI::dbGetQuery(
        con, "SELECT content FROM read_text(?)",
        params = list(paste0(release_url, "views.sql"))
      )$content
      DBI::dbExecute(con, views_sql)
    } else {
      DBI::dbExecute(con, paste0(
        "ATTACH ", DBI::dbQuoteString(con, paste0(release_url, "omicidx.duckdb")),
        " AS omicidx (READ_ONLY); USE omicidx;"
      ))
    },
    error = function(e) {
      if (grepl("404|does not exist", conditionMessage(e))) {
        stop(
          "OmicIDX release '", version, "' was not found at ", release_url, ".\n",
          "Dated releases are kept for 30 days. For older or citable data, use a ",
          "monthly release, e.g. omicidx_connect(\"YYYY-MM\").",
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

#' Which OmicIDX release a connection is on
#'
#' The release a connection from [omicidx_connect()] points at, with
#' the provenance recorded in the release's `manifest.json`. Cite
#' `version` and `publish_date`; `transform_sha` and `lake_snapshot_id`
#' identify exactly how and from what the release was built.
#'
#' @inheritParams omicidx_tables
#'
#' @return A list with `version` (as passed to [omicidx_connect()]),
#'   `url` (the release folder), and from `manifest.json`:
#'   `publish_date`, `transform_sha` (the commit of the OmicIDX
#'   transform code), `lake_snapshot_id` (the source data snapshot) and
#'   `tables` (a tibble of `schema`, `table` and `row_count`). The
#'   manifest fields are `NA` (`tables` is `NULL`) if `manifest.json`
#'   could not be read.
#'
#' @examples
#' \donttest{
#' con <- omicidx_connect()
#' omicidx_release(con)$publish_date
#' DBI::dbDisconnect(con)
#' }
#'
#' @export
omicidx_release <- function(con) {
  release <- attr(omicidx_con(con), "omicidx_release")
  if (is.null(release)) {
    stop("`con` was not opened by omicidx_connect().", call. = FALSE)
  }
  release
}

# The release's manifest.json describes the data but is not needed to query
# it, so an unreadable manifest leaves NA fields instead of failing.
read_release <- function(con, version, url) {
  release <- list(
    version = version, url = url, publish_date = NA_character_,
    transform_sha = NA_character_, lake_snapshot_id = NA_real_, tables = NULL
  )
  m <- tryCatch(DBI::dbGetQuery(con, "
    SELECT publish_date::VARCHAR AS publish_date, transform_sha,
           lake_snapshot_id, unnest(tables, recursive := true)
    FROM read_json(?)", params = list(paste0(url, "manifest.json"))),
    error = function(e) NULL
  )
  if (is.null(m) || nrow(m) == 0L) return(release)
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
      "https://huggingface.co/datasets/omicidx/omicidx/resolve/%s/", version
    ))
  }
  stop(
    "`version` must be \"latest\", a date \"YYYY-MM-DD\" or a month \"YYYY-MM\", ",
    "not '", version, "'.",
    call. = FALSE
  )
}
