# Connect to the Omicidx DuckDB Database

Establishes a connection to the public Omicidx DuckDB database hosted on
an S3-compatible object store. The database is attached to a DuckDB
instance, which can be either in-memory or backed by a local file.

## Usage

``` r
connect_omicidx(db_path = ":memory:")
```

## Arguments

- db_path:

  character(1) Path passed to DuckDB as `dbdir`. Use `":memory:"` for an
  in-memory database (default).

## Value

A DuckDB connection object.

## Examples

``` r
con <- connect_omicidx()
DBI::dbListTables(con)
#>  [1] "experiment"                        "geo_supplemental_files"           
#>  [3] "gpl"                               "gse"                              
#>  [5] "gse_gpl"                           "gse_gsm"                          
#>  [7] "gsm"                               "human_runs"                       
#>  [9] "mouse_runs"                        "rnaseq_runs"                      
#> [11] "run"                               "run_with_study"                   
#> [13] "sample"                            "sra"                              
#> [15] "src_bioprojects"                   "src_biosamples"                   
#> [17] "src_geo_platforms"                 "src_geo_samples"                  
#> [19] "src_geo_series"                    "src_geo_series_with_rnaseq_counts"
#> [21] "src_sra_accessions"                "src_sra_experiments"              
#> [23] "src_sra_runs"                      "src_sra_samples"                  
#> [25] "src_sra_studies"                   "stg_bioprojects"                  
#> [27] "stg_biosamples"                    "stg_geo_platforms"                
#> [29] "stg_geo_samples"                   "stg_geo_series"                   
#> [31] "stg_sra_experiments"               "stg_sra_runs"                     
#> [33] "stg_sra_samples"                   "stg_sra_studies"                  
#> [35] "study"                             "wgs_runs"                         
# or use dplyr
# dplyr::tbl(con, "some_table")
```
