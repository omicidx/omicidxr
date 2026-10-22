# SRA runs for studies, experiments, samples or GEO accessions

The runs behind each accession, with the fields needed to choose and
download them: pass `run_accession` to `prefetch` or `fasterq-dump` from
the SRA Toolkit. File URLs, sizes and checksums, as given by
`SRAdb::listSRAfile()`, are out of scope.

## Usage

``` r
sra_runs(con, in_acc)
```

## Arguments

- con:

  A connection from
  [`omicidx_connect()`](https://seandavi.github.io/omicidxr/reference/omicidx_connect.md),
  or an
  [`omicidx_db()`](https://seandavi.github.io/omicidxr/reference/omicidx_db.md).

- in_acc:

  character. Accessions of any type
  [`sra_convert()`](https://seandavi.github.io/omicidxr/reference/sra_convert.md)
  supports, for example studies, experiments or GSEs.

## Value

A tibble with one row per run: its accessions, `spots`, `bases`, library
strategy, source, selection and layout, platform, instrument model and
organism.

## Examples

``` r
con <- omicidx_connect()
sra_runs(con, "SRP000001")
#> # A tibble: 83 × 17
#>    run_accession experiment_accession sample_accession study_accession
#>    <chr>         <chr>                <chr>            <chr>          
#>  1 SRR000001     SRX000007            SRS000100        SRP000001      
#>  2 SRR000002     SRX000006            SRS000100        SRP000001      
#>  3 SRR000003     SRX000005            SRS000100        SRP000001      
#>  4 SRR000004     SRX000002            SRS000605        SRP000001      
#>  5 SRR000005     SRX000006            SRS000100        SRP000001      
#>  6 SRR000006     SRX000004            SRS000100        SRP000001      
#>  7 SRR000007     SRX000003            SRS000100        SRP000001      
#>  8 SRR000008     SRX000006            SRS000100        SRP000001      
#>  9 SRR000009     SRX000004            SRS000100        SRP000001      
#> 10 SRR000010     SRX000004            SRS000100        SRP000001      
#> # ℹ 73 more rows
#> # ℹ 13 more variables: biosample_accession <chr>, bioproject_accession <chr>,
#> #   spots <dbl>, bases <dbl>, library_strategy <chr>, library_source <chr>,
#> #   library_selection <chr>, library_layout <chr>, platform <chr>,
#> #   instrument_model <chr>, scientific_name <chr>, taxon_id <int>,
#> #   experiment_title <chr>
DBI::dbDisconnect(con)
```
