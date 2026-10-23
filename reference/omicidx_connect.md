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
[`omicidx_release()`](https://seandavi.github.io/omicidxr/reference/omicidx_release.md)
tells which release it is connected to.

## Details

After connecting, tables are referenced as `schema.table`, for example
`sradb.study` or `geometadb.gsm`. Use
[`omicidx_tables()`](https://seandavi.github.io/omicidxr/reference/omicidx_tables.md)
to list them and
[`omicidx_db()`](https://seandavi.github.io/omicidxr/reference/omicidx_db.md)
for tab-completable `dplyr` tables.

## Versions

- `"latest"`: the nightly build at
  `https://omicidx.cancerdatasci.org/data/latest/`.

- `"YYYY-MM-DD"`: a dated nightly build, kept for 30 days.

- `"YYYY-MM"`: a monthly release on HuggingFace
  (`seandavis/omicidx@YYYY-MM`). Monthly releases are kept long term and
  are the version to cite.

Query `"latest"` and dated builds in place: they are served without rate
limits. Treat monthly releases as the archive: copy one with
`omicidx_download("YYYY-MM", path)` and query the local file. Connecting
to a monthly release in place works, but takes about 30 seconds (DuckDB
inspects every Parquet file while it creates the views) and runs into
HuggingFace's rate limits.

## HuggingFace rate limits

HuggingFace allows 3000 anonymous requests per 5 minutes per IP address,
and connecting to a monthly release or running one query can make
hundreds, so heavy use, or a shared IP address, fails with HTTP 429 (Too
Many Requests) until the window resets. To avoid it:

- Download the release with
  [`omicidx_download()`](https://seandavi.github.io/omicidxr/reference/omicidx_download.md),
  which waits out the limit, and query the local copy.

- Set the environment variable `HF_TOKEN` to a HuggingFace access token,
  which raises the limit to that of a signed-in user.

- Within 30 days of a monthly release, connect to the dated build it was
  published from (`omicidx_release(con)$publish_date`), which holds the
  same data.

## Timeouts

Each HTTP request times out after 30 seconds and is retried up to 4
times, after waits of 0, 1, 4 and 16 seconds, which also rides out a
brief HTTP 429. If connecting still fails, `omicidx_connect()` stops
with an error naming the release URL.

Requests carry the User-Agent `omicidxr/<package version>`. DuckDB
extensions (`httpfs`, `json`) are downloaded once and cached in
`tools::R_user_dir("omicidxr", "cache")`. The connection neither uses
`~/.duckdb` nor reads DuckDB secrets persisted there.

## Examples

``` r
con <- omicidx_connect()
DBI::dbGetQuery(con, "SELECT count(*) AS n FROM sradb.study")
#>        n
#> 1 775372
DBI::dbDisconnect(con)
```
