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
  [`omicidx_connect()`](https://seandavi.github.io/omicidxr/reference/omicidx_connect.md),
  or a version string to open a new one. Defaults to `version`.

- version:

  character(1). Release to connect to when `con` is `NULL`; see
  [`omicidx_connect()`](https://seandavi.github.io/omicidxr/reference/omicidx_connect.md).

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
#> <omicidx_db> OmicIDX release latest (published 2026-10-23)
#> 
#> geometadb
#>   geo_supplemental_files    7,098,064
#>   gpl                          29,060
#>   gse                         298,108
#>   gse_gpl                     345,076
#>   gse_gsm                  10,562,000
#>   gsm                       8,774,090
#> 
#> main
#>   bioprojects                      1,130,284
#>   biosamples                      60,484,224
#>   db_creation_metadata
#>   geo_platforms                       29,060
#>   geo_samples                      8,774,090
#>   geo_series                         298,108
#>   geo_series_with_rnaseq_counts       27,714
#>   pubmed_articles                 41,275,240
#>   sra_accessions                 162,991,962
#>   sra_experiments                 42,655,706
#>   sra_runs                        45,553,970
#>   sra_samples                     44,670,639
#>   sra_studies                        775,372
#> 
#> sradb
#>   experiment       42,655,706
#>   human_runs        8,540,117
#>   mouse_runs        4,415,567
#>   rnaseq_runs       9,054,381
#>   run              45,699,354
#>   run_with_study   45,699,354
#>   sample           44,670,639
#>   sra              45,699,354
#>   study               775,372
#>   wgs_runs          9,601,400
#> 
#> Tables: db$<schema>$<table>. Connection: attr(db, "con").
db$sradb$study |>
    dplyr::count(study_type, sort = TRUE) |>
    head() |>
    dplyr::collect()
#> # A tibble: 6 × 2
#>   study_type                   n
#>   <chr>                    <dbl>
#> 1 Other                   443600
#> 2 Transcriptome Analysis  129664
#> 3 Whole Genome Sequencing 128310
#> 4 Metagenomics             71399
#> 5 Population Genomics        836
#> 6 Epigenetics                707
DBI::dbDisconnect(attr(db, "con"))
```
