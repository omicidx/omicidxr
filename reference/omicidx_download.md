# Download an OmicIDX release into a local DuckDB file

Copies the tables of a release into a new DuckDB database file, so they
can be queried offline and at local-disk speed. The copy is checked
against the row counts in the release's `manifest.json`. This is the R
counterpart of the `restore.sql` published with each nightly build.

## Usage

``` r
omicidx_download(version = "latest", path, tables = NULL)
```

## Arguments

- version:

  character(1). `"latest"` (default), a date `"YYYY-MM-DD"` or a month
  `"YYYY-MM"`. See the Versions section.

- path:

  character(1). The DuckDB file to create. It must not exist.

- tables:

  character. The tables to copy, as `"schema.table"` (for example
  `"sradb.study"` or `"main.sra_runs"`) or whole schemas (for example
  `"sradb"`). `NULL` (default) copies every table.
  [`omicidx_tables()`](https://seandavi.github.io/omicidxr/reference/omicidx_tables.md)
  lists them.

## Value

`path`, invisibly. Open it with
`DBI::dbConnect(duckdb::duckdb(), path)`; tables keep their names, for
example `sradb.study`.

## Details

A full release is large: about 75 GB of Parquet, which becomes a DuckDB
file about 5 times that size (400 GB for `"2026-10"`), and took about an
hour to copy. Pass `tables` to copy only what you need, such as the
`"sradb"` or `"geometadb"` marts. Before copying, `omicidx_download()`
reports the size of the Parquet it will read.

Tables are copied one at a time. Copying a monthly release makes tens of
thousands of requests to HuggingFace, more than its rate limit allows in
5 minutes (see
[`omicidx_connect()`](https://seandavi.github.io/omicidxr/reference/omicidx_connect.md)),
so each request is retried for up to 6 minutes and the copy pauses while
the limit resets. Setting `HF_TOKEN` raises the limit.

## Examples

``` r
path <- omicidx_download(
    "latest", tempfile(fileext = ".duckdb"), tables = "geometadb.gpl"
)
#> Copying 1 tables, about 0.0024 GB of Parquet, to /tmp/RtmpRefzl8/file1b097b683f8d.duckdb. The DuckDB file can be several times larger.
#> Copying geometadb.gpl
con <- DBI::dbConnect(duckdb::duckdb(), path, read_only = TRUE)
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpRefzl8/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
DBI::dbGetQuery(con, "SELECT count(*) AS n FROM geometadb.gpl")
#>       n
#> 1 29060
DBI::dbDisconnect(con)
```
