# Tab-completable lazy tables for an OmicIDX release

Returns every table in the release as a lazy `dplyr` table, nested by
schema, so that `db$sradb$<TAB>` completes table names. Each table is
built the first time it is accessed, and no data are read until a query
is run (for example with
[`dplyr::collect()`](https://dplyr.tidyverse.org/reference/compute.html)).

## Usage

``` r
omicidx_db(con = NULL, version = "latest")
```

## Arguments

- con:

  A connection from
  [`omicidx_connect()`](https://omicidx.github.io/omicidxr/reference/omicidx_connect.md),
  or a version string to open a new one. Defaults to `version`.

- version:

  character(1). Release to connect to when `con` is `NULL`; see
  [`omicidx_connect()`](https://omicidx.github.io/omicidxr/reference/omicidx_connect.md).

## Value

An `omicidx_db` object: a named list with one element per schema, each
an environment of lazy tables. The connection is available as
`attr(db, "con")`, and its release, with row counts, as
`omicidx_release(db)`. All omicidxr helpers accept an `omicidx_db` in
place of a connection.

## Examples

``` r
db <- omicidx_db()
db
#> <omicidx_db> OmicIDX release latest (published 2026-10-20)
#> 
#> geometadb
#>   geo_supplemental_files    7,026,380
#>   gpl                          28,819
#>   gse                         293,571
#>   gse_gpl                     341,054
#>   gse_gsm                  10,447,481
#>   gsm                       8,678,255
#> 
#> main
#>   db_creation_metadata
#> 
#> sradb
#>   experiment       42,615,764
#>   human_runs        8,535,912
#>   mouse_runs        4,413,081
#>   rnaseq_runs       9,046,637
#>   run              45,638,775
#>   run_with_study   45,638,775
#>   sample           44,636,830
#>   sra              45,638,775
#>   study               774,584
#>   wgs_runs          9,589,280
#> 
#> Tables: db$<schema>$<table>. Connection: attr(db, "con").
db$sradb$study |>
    dplyr::count(study_type, sort = TRUE) |>
    head() |>
    dplyr::collect()
#> # A tibble: 6 × 2
#>   study_type                   n
#>   <chr>                    <dbl>
#> 1 Other                   443270
#> 2 Transcriptome Analysis  129505
#> 3 Whole Genome Sequencing 128220
#> 4 Metagenomics             71379
#> 5 Population Genomics        836
#> 6 Epigenetics                707
DBI::dbDisconnect(attr(db, "con"))
```
