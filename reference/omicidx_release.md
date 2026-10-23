# Which OmicIDX release a connection is on

The release a connection from
[`omicidx_connect()`](https://seandavi.github.io/omicidxr/reference/omicidx_connect.md)
points at, with the provenance recorded in the release's
`manifest.json`. Cite `version` and `publish_date`; `transform_sha` and
`lake_snapshot_id` identify exactly how and from what the release was
built.

## Usage

``` r
omicidx_release(con)
```

## Arguments

- con:

  A connection from
  [`omicidx_connect()`](https://seandavi.github.io/omicidxr/reference/omicidx_connect.md),
  or an
  [`omicidx_db()`](https://seandavi.github.io/omicidxr/reference/omicidx_db.md)
  object.

## Value

A list with `version` (as passed to
[`omicidx_connect()`](https://seandavi.github.io/omicidxr/reference/omicidx_connect.md)),
`url` (the release folder), and from `manifest.json`: `publish_date`,
`transform_sha` (the commit of the OmicIDX transform code),
`lake_snapshot_id` (the source data snapshot) and `tables` (a tibble of
`schema`, `table` and `row_count`). The manifest fields are `NA`
(`tables` is `NULL`) if `manifest.json` could not be read.

## Examples

``` r
con <- omicidx_connect()
omicidx_release(con)$publish_date
#> [1] "2026-10-23"
DBI::dbDisconnect(con)
```
