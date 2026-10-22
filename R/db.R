#' List the tables in an OmicIDX connection
#'
#' @param con A connection from [omicidx_connect()], or an [omicidx_db()]
#'   object.
#'
#' @return A tibble with columns `schema`, `table` and `type` (`"VIEW"`
#'   or `"BASE TABLE"`), one row per table.
#'
#' @examples
#' \donttest{
#' con <- omicidx_connect()
#' omicidx_tables(con)
#' DBI::dbDisconnect(con)
#' }
#'
#' @export
omicidx_tables <- function(con) {
  con <- omicidx_con(con)
  tibble::as_tibble(DBI::dbGetQuery(con, "
    SELECT table_schema AS schema, table_name AS \"table\", table_type AS type
    FROM information_schema.tables
    WHERE table_catalog = current_database()
    ORDER BY schema, \"table\""))
}

#' Describe the columns of an OmicIDX table
#'
#' @inheritParams omicidx_tables
#' @param table character(1). A table name, schema-qualified as in
#'   `"sradb.study"`. Unqualified names are looked up in `main`.
#'
#' @return A tibble with one row per column: `column_name`,
#'   `column_type` and `null` (whether the column may hold `NULL`s).
#'
#' @examples
#' \donttest{
#' con <- omicidx_connect()
#' omicidx_describe(con, "sradb.study")
#' DBI::dbDisconnect(con)
#' }
#'
#' @export
omicidx_describe <- function(con, table) {
  con <- omicidx_con(con)
  stopifnot(is.character(table), length(table) == 1L)
  name <- paste(DBI::dbQuoteIdentifier(con, strsplit(table, ".", fixed = TRUE)[[1]]),
                collapse = ".")
  res <- DBI::dbGetQuery(con, paste("DESCRIBE", name))
  tibble::as_tibble(res[c("column_name", "column_type", "null")])
}

#' Tab-completable lazy tables for an OmicIDX release
#'
#' Returns every table in the release as a lazy `dplyr` table, nested
#' by schema, so that `db$sradb$<TAB>` completes table names. Each
#' table is built the first time it is accessed, and no data are read
#' until a query is run (for example with [dplyr::collect()]).
#'
#' @param con A connection from [omicidx_connect()], or a version
#'   string to open a new one. Defaults to `version`.
#' @param version character(1). Release to connect to when `con` is
#'   `NULL`; see [omicidx_connect()].
#'
#' @return An `omicidx_db` object: a named list with one element per
#'   schema, each an environment of lazy tables. The connection is
#'   available as `attr(db, "con")`, and the release manifest (with row
#'   counts), when available, as `attr(db, "manifest")`. All omicidxr
#'   helpers accept an `omicidx_db` in place of a connection.
#'
#' @examples
#' \donttest{
#' db <- omicidx_db()
#' db
#' db$sradb$study |>
#'   dplyr::count(study_type, sort = TRUE) |>
#'   head() |>
#'   dplyr::collect()
#' DBI::dbDisconnect(attr(db, "con"))
#' }
#'
#' @export
omicidx_db <- function(con = NULL, version = "latest") {
  if (is.null(con) || is.character(con)) {
    con <- omicidx_connect(if (is.null(con)) version else con)
  }
  con <- omicidx_con(con)
  tables <- omicidx_tables(con)
  # ponytail: tbl() probes each view's columns over HTTPS (~1s per table, ~20s
  # for the whole release), so tables are promises, built on first access.
  by_schema <- split(tables$table, tables$schema)
  schemas <- Map(function(schema, names) {
    env <- new.env(parent = emptyenv())
    for (name in names) lazy_tbl(env, con, schema, name)
    structure(env, class = "omicidx_schema")
  }, names(by_schema), by_schema)
  structure(schemas, class = "omicidx_db", con = con,
            manifest = omicidx_manifest(con))
}

lazy_tbl <- function(env, con, schema, name) {
  force(schema)
  force(name)
  delayedAssign(name, dplyr::tbl(con, I(paste(schema, name, sep = "."))),
                assign.env = env)
}

#' @export
print.omicidx_db <- function(x, ...) {
  manifest <- attr(x, "manifest")
  version <- omicidx_variable(attr(x, "con"), "omicidx_version")
  cat("<omicidx_db>", if (!is.null(version)) paste("OmicIDX release", version))
  if (!is.null(manifest$publish_date)) {
    cat(" (published ", manifest$publish_date, ")", sep = "")
  }
  cat("\n")
  for (schema in names(x)) {
    tables <- sort(ls(x[[schema]]))
    rows <- manifest$tables[manifest$tables$schema == schema, ]
    n <- rows$row_count[match(tables, rows$table)]
    n <- ifelse(is.na(n), "", format(n, big.mark = ",", scientific = FALSE))
    cat("\n", schema, "\n", sep = "")
    cat(trimws(sprintf("  %-*s %12s", max(nchar(tables)), tables, n), "right"),
        sep = "\n")
  }
  cat("\nTables: db$<schema>$<table>. Connection: attr(db, \"con\").\n")
  invisible(x)
}

#' @export
print.omicidx_schema <- function(x, ...) {
  cat("<omicidx_schema> lazy tables:", paste(sort(ls(x)), collapse = ", "), "\n")
  invisible(x)
}

# Accept an omicidx_db wherever a connection is expected.
omicidx_con <- function(con) {
  if (inherits(con, "omicidx_db")) con <- attr(con, "con")
  if (!inherits(con, "DBIConnection")) {
    stop("`con` must be a connection from omicidx_connect() or an omicidx_db().",
         call. = FALSE)
  }
  con
}

# Values stored by omicidx_connect(); NULL for other connections.
omicidx_variable <- function(con, name) {
  DBI::dbGetQuery(con, "SELECT getvariable(?) AS v", params = list(name))$v[[1]]
}

# The release's manifest.json: publish_date plus per-table row counts.
# NULL when unavailable, since it only decorates print().
omicidx_manifest <- function(con) {
  url <- omicidx_variable(con, "omicidx_release_url")
  if (is.null(url) || is.na(url)) return(NULL)
  tryCatch({
    tables <- DBI::dbGetQuery(con, "
      SELECT publish_date::VARCHAR AS publish_date,
             unnest(tables, recursive := true)
      FROM read_json(?)", params = list(paste0(url, "manifest.json")))
    list(publish_date = tables$publish_date[1],
         tables = tables[c("schema", "table", "row_count")])
  }, error = function(e) NULL)
}
