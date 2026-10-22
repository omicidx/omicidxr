# Connect to an OmicIDX release

Opens an in-memory DuckDB database and makes an OmicIDX release
available in it. Nothing is downloaded up front: queries read the remote
Parquet files over HTTPS, fetching only the columns and row groups they
need.

## Usage

``` r
omicidx_connect(version = "latest")
```

## Arguments

- version:

  character(1). `"latest"` (default), a date `"YYYY-MM-DD"` or a month
  `"YYYY-MM"`. See the Versions section.

## Value

A DuckDB
[DBI::DBIConnection](https://dbi.r-dbi.org/reference/DBIConnection-class.html).
Close it with
[`DBI::dbDisconnect()`](https://dbi.r-dbi.org/reference/dbDisconnect.html).
[`omicidx_release()`](https://omicidx.github.io/omicidxr/reference/omicidx_release.md)
tells which release it is connected to.

## Details

After connecting, tables are referenced as `schema.table`, for example
`sradb.study` or `geometadb.gsm`. Use
[`omicidx_tables()`](https://omicidx.github.io/omicidxr/reference/omicidx_tables.md)
to list them and
[`omicidx_db()`](https://omicidx.github.io/omicidxr/reference/omicidx_db.md)
for tab-completable `dplyr` tables.

## Versions

- `"latest"`: the nightly build at
  `https://omicidx.cancerdatasci.org/data/latest/`.

- `"YYYY-MM-DD"`: a dated nightly build, kept for 30 days.

- `"YYYY-MM"`: a monthly release on HuggingFace
  (`omicidx/omicidx@YYYY-MM`). Monthly releases are kept long term and
  are the version to cite. Connecting takes longer (about 30 seconds)
  because DuckDB inspects every Parquet file while it creates the views.
  HuggingFace limits anonymous requests (3000 per 5 minutes per IP
  address) and one query can make hundreds, so heavy use can fail with
  HTTP 429 until the window resets.

Requests carry the User-Agent `omicidxr/<package version>`. DuckDB
extensions (`httpfs`, `json`) are downloaded once and cached in
`tools::R_user_dir("omicidxr", "cache")`. The connection neither uses
`~/.duckdb` nor reads DuckDB secrets persisted there.

## Examples

``` r
con <- omicidx_connect()
DBI::dbGetQuery(con, "SELECT count(*) AS n FROM sradb.study")
#>        n
#> 1 774773
DBI::dbDisconnect(con)
```
