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
#> [1] "v_src_geo_platforms"   "v_src_geo_samples"     "v_src_geo_series"     
#> [4] "v_src_sra_accessions"  "v_src_sra_experiments" "v_src_sra_runs"       
#> [7] "v_src_sra_samples"     "v_src_sra_studies"    
# or use dplyr
# dplyr::tbl(con, "some_table")
```
