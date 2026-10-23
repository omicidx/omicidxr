# Download an OmicIDX release into a local DuckDB file

Copies every table of a release into a new DuckDB database file, so it
can be queried offline and at local-disk speed. The copy is checked
against the row counts in the release's `manifest.json`. This is the R
counterpart of the `restore.sql` published with each nightly build.

## Usage

``` r
omicidx_download(version = "latest", path)
```

## Arguments

- version:

  character(1). `"latest"` (default), a date `"YYYY-MM-DD"` or a month
  `"YYYY-MM"`. See the Versions section.

- path:

  character(1). The DuckDB file to create. It must not exist.

## Value

`path`, invisibly. Open it with
`DBI::dbConnect(duckdb::duckdb(), path)`; tables keep their names, for
example `sradb.study`.

## Details

A full release is large (tens of GB) and takes a while to copy.

## Examples

``` r
if (FALSE) { # \dontrun{
path <- omicidx_download("2026-10", "omicidx-2026-10.duckdb")
con <- DBI::dbConnect(duckdb::duckdb(), path, read_only = TRUE)
DBI::dbGetQuery(con, "SELECT count(*) AS n FROM sradb.study")
DBI::dbDisconnect(con)
} # }
```
