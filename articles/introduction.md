# Getting Started with omicidx in R

OmicIDX collects metadata from SRA, GEO, BioSample and BioProject and
publishes it as Parquet files. `omicidxr` connects DuckDB to those
files, so you can query tens of millions of records with SQL or `dplyr`
without downloading them.

## Connecting

[`omicidx_connect()`](https://omicidx.github.io/omicidxr/reference/omicidx_connect.md)
returns an ordinary DuckDB DBI connection. The `version` argument picks
the release: `"latest"` (the nightly build, the default), a dated
nightly build `"YYYY-MM-DD"` (kept for 30 days), or a monthly release
`"YYYY-MM"`, which is kept long term and is the one to cite. This
vignette pins the October 2026 monthly release so its results are
reproducible.

``` r

library(omicidxr)

con <- omicidx_connect("2026-10")
```

## What is in a release

``` r

omicidx_tables(con)
#> # A tibble: 28 × 3
#>    schema    table                  type 
#>    <chr>     <chr>                  <chr>
#>  1 geometadb geo_supplemental_files VIEW 
#>  2 geometadb gpl                    VIEW 
#>  3 geometadb gse                    VIEW 
#>  4 geometadb gse_gpl                VIEW 
#>  5 geometadb gse_gsm                VIEW 
#>  6 geometadb gsm                    VIEW 
#>  7 main      bioprojects            VIEW 
#>  8 main      biosamples             VIEW 
#>  9 main      geo_platforms          VIEW 
#> 10 main      geo_samples            VIEW 
#> # ℹ 18 more rows
```

The `sradb` and `geometadb` schemas follow the tables of the SRAdb and
GEOmetadb packages.
[`omicidx_describe()`](https://omicidx.github.io/omicidxr/reference/omicidx_describe.md)
lists a table’s columns:

``` r

omicidx_describe(con, "sradb.study")
#> # A tibble: 14 × 3
#>    column_name          column_type null 
#>    <chr>                <chr>       <chr>
#>  1 study_id             BIGINT      YES  
#>  2 study_alias          VARCHAR     YES  
#>  3 study_accession      VARCHAR     YES  
#>  4 study_title          VARCHAR     YES  
#>  5 study_type           VARCHAR     YES  
#>  6 study_abstract       VARCHAR     YES  
#>  7 broker_name          VARCHAR     YES  
#>  8 center_name          VARCHAR     YES  
#>  9 center_project_name  VARCHAR     YES  
#> 10 study_description    VARCHAR     YES  
#> 11 study_attribute      VARCHAR     YES  
#> 12 bioproject_accession VARCHAR     YES  
#> 13 geo_accession        VARCHAR     YES  
#> 14 pubmed_ids           VARCHAR[]   YES
```

## SQL

Any DuckDB SQL works through DBI. Keep exploratory queries small with
`LIMIT`: every query reads remote files.

``` r

DBI::dbGetQuery(con, "
  SELECT study_accession, study_title
  FROM sradb.study
  WHERE study_type = 'Transcriptome Analysis'
  LIMIT 5")
#>   study_accession
#> 1       DRP000003
#> 2       DRP000004
#> 3       DRP000005
#> 4       DRP000006
#> 5       DRP000007
#>                                                                                                                                study_title
#> 1                                                Comprehensive identification and characterization of the nucleosome             structure
#> 2 Comprehensive identification and characterization of the transcripts, their             expression levels and sub-cellular localizations
#> 3 Comprehensive identification and characterization of the transcripts, their             expression levels and sub-cellular localizations
#> 4 Comprehensive identification and characterization of the transcripts, their             expression levels and sub-cellular localizations
#> 5                                      Comprehensive identification and characterization of the binding sites of             polymerase II
```

## dplyr

[`omicidx_db()`](https://omicidx.github.io/omicidxr/reference/omicidx_db.md)
wraps the connection as lazy `dplyr` tables nested by schema, so
`db$sradb$<TAB>` completes table names. Each table is created when first
used, and nothing is read until `collect()`.

``` r

db <- omicidx_db(con)
db
#> <omicidx_db> OmicIDX release 2026-10 (published 2026-10-20)
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
#>   bioprojects
#>   biosamples
#>   geo_platforms
#>   geo_samples
#>   geo_series
#>   geo_series_with_rnaseq_counts
#>   pubmed_articles
#>   sra_accessions
#>   sra_experiments
#>   sra_runs
#>   sra_samples
#>   sra_studies
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

db$geometadb$gse |>
  dplyr::filter(title %ILIKE% "%single cell%") |>
  dplyr::select(gse, title, submission_date) |>
  head(5) |>
  dplyr::collect()
#> # A tibble: 5 × 3
#>   gse       title                                                submission_date
#>   <chr>     <chr>                                                <date>         
#> 1 GSE240638 Gene expression profile at the single cell level of… 2023-08-10     
#> 2 GSE241743 The single cell transcriptomic profiling in iPSC de… 2023-08-26     
#> 3 GSE241996 Single cell RNA sequencing monitoring the developme… 2023-08-30     
#> 4 GSE241997 Single cell RNA sequencing of the in vivo mouse TME  2023-08-30     
#> 5 GSE242428 Characterization of CD4+ and CD8+ T cells responses… 2023-09-06
```

## SRAdb and GEOmetadb helpers

A few helpers cover the common SRAdb and GEOmetadb tasks. Each runs one
query and returns a tibble.

Convert accessions across SRA, GEO, BioSample and BioProject, in any
direction:

``` r

sra_convert(con, "GSM4996084", c("gse", "study", "experiment", "run"))
#> # A tibble: 4 × 5
#>   study     experiment run         gse       gsm       
#>   <chr>     <chr>      <chr>       <chr>     <chr>     
#> 1 SRP299835 SRX9759115 SRR13332242 GSE164073 GSM4996084
#> 2 SRP299835 SRX9759115 SRR13332243 GSE164073 GSM4996084
#> 3 SRP299835 SRX9759115 SRR13332244 GSE164073 GSM4996084
#> 4 SRP299835 SRX9759115 SRR13332245 GSE164073 GSM4996084
```

The samples and platform of a GEO series, and the characteristics of its
samples:

``` r

geo_samples(con, "GSE164073") |>
  dplyr::select(gsm, title, gpl, platform_title, sra_experiment) |>
  head()
#> # A tibble: 6 × 5
#>   gsm        title         gpl      platform_title                sra_experiment
#>   <chr>      <chr>         <chr>    <chr>                         <chr>         
#> 1 GSM4996084 Cornea_mock_1 GPL18573 Illumina NextSeq 500 (Homo s… SRX9759115    
#> 2 GSM4996085 Cornea_mock_2 GPL18573 Illumina NextSeq 500 (Homo s… SRX9759116    
#> 3 GSM4996086 Cornea_mock_3 GPL18573 Illumina NextSeq 500 (Homo s… SRX9759117    
#> 4 GSM4996087 Cornea_CoV2_1 GPL18573 Illumina NextSeq 500 (Homo s… SRX9759118    
#> 5 GSM4996088 Cornea_CoV2_2 GPL18573 Illumina NextSeq 500 (Homo s… SRX9759119    
#> 6 GSM4996089 Cornea_CoV2_3 GPL18573 Illumina NextSeq 500 (Homo s… SRX9759120

geo_characteristics(con, c("GSM4996084", "GSM4996087"))
#> # A tibble: 6 × 4
#>   gsm        channel tag        value                
#>   <chr>        <int> <chr>      <chr>                
#> 1 GSM4996084       1 tissue     cornea               
#> 2 GSM4996084       1 infection  mock                 
#> 3 GSM4996084       1 time point 24 hours             
#> 4 GSM4996087       1 tissue     cornea               
#> 5 GSM4996087       1 infection  SARS-CoV-2, MOI = 1.0
#> 6 GSM4996087       1 time point 24 hours
```

The runs to download for a study, experiment or GEO series:

``` r

sra_runs(con, "GSE164073") |>
  dplyr::select(run_accession, library_layout, spots, bases, instrument_model) |>
  head()
#> # A tibble: 6 × 5
#>   run_accession library_layout   spots     bases instrument_model
#>   <chr>         <chr>            <dbl>     <dbl> <chr>           
#> 1 SRR13332242   SINGLE         5970564 827055768 NextSeq 500     
#> 2 SRR13332243   SINGLE         6168624 854329747 NextSeq 500     
#> 3 SRR13332244   SINGLE         6135802 849819102 NextSeq 500     
#> 4 SRR13332245   SINGLE         6012012 832302560 NextSeq 500     
#> 5 SRR13332246   SINGLE         6696443 925556551 NextSeq 500     
#> 6 SRR13332247   SINGLE         6917201 955889361 NextSeq 500
```

Search study and series titles and abstracts:

``` r

sra_search(con, "single cell%glioma", limit = 5) |>
  dplyr::select(study_accession, study_title)
#> # A tibble: 5 × 2
#>   study_accession study_title                                                   
#>   <chr>           <chr>                                                         
#> 1 ERP144083       Longitudinal scRNA-Seq of immune cells from GL261 murine brai…
#> 2 SRP042161       Single cell RNA-seq of primary human glioblastomas            
#> 3 SRP060524       Single cell RNA-seq analysis of oligodendroglioma             
#> 4 SRP067604       Single cell transcriptome dynamics and subpopulation heteroge…
#> 5 SRP081644       An automatec microwell platform for large-scale single cell R…
geo_search(con, "glioblastoma", limit = 5) |>
  dplyr::select(gse, title)
#> # A tibble: 5 × 2
#>   gse       title                                                               
#>   <chr>     <chr>                                                               
#> 1 GSE102136 Single Copy Loss of Tet1 disrupts neural stem cell differentiation …
#> 2 GSE108013 Microenvironmental-derived Regulation of HIF-Signaling Drives Trans…
#> 3 GSE241037 spatiotemporal single-cell transcriptomics in mouse and human to in…
#> 4 GSE242790 Repeated peripheral infusions of anti-EGFRvIII CAR T cells in combi…
#> 5 GSE248352 Antitumor effects of intravenous natural killer cell infusion in an…
```

## Migrating from SRAdb and GEOmetadb

SRAdb and GEOmetadb are deprecated. Their SQLite files had to be
downloaded whole and are no longer updated. The `sradb` and `geometadb`
schemas follow their tables, so most code ports by connecting with
[`omicidx_connect()`](https://omicidx.github.io/omicidxr/reference/omicidx_connect.md)
and prefixing table names with the schema.

| SRAdb / GEOmetadb | omicidxr |
|----|----|
| `getSRAdbFile()`, `getSQLiteFile()`, then `dbConnect(SQLite(), ...)` | `con <- omicidx_connect()` |
| `dbGetQuery(sra_con, "SELECT * FROM study ...")` | `DBI::dbGetQuery(con, "SELECT * FROM sradb.study ...")` |
| `dbGetQuery(geo_con, "SELECT * FROM gsm ...")` | `DBI::dbGetQuery(con, "SELECT * FROM geometadb.gsm ...")` |
| `dbListTables()`, `dbListFields()` | `omicidx_tables(con)`, `omicidx_describe(con, "sradb.run")` |
| `sraConvert(in_acc, out_type, sra_con)` | `sra_convert(con, in_acc, out_type)` |
| `geoConvert(in_list, out_type, geo_con)` | `geo_convert(con, in_list, out_type)` |
| `getSRA(search_terms, out_types, sra_con)` | `sra_search(con, query)` |
| `getSRAinfo()`, `listSRAfile()` | `sra_runs(con, in_acc)`: run accessions for the SRA Toolkit, not file URLs |
| `characteristics_ch1` parsed by hand | `geo_characteristics(con, gsm)` |

Differences to watch for:

- The connection comes first in every helper, so they work with `|>`.
- Tables are schema-qualified: `sradb.study`, not `study`.
- Conversion also covers BioSample and BioProject, but not SRA
  submissions or GEO DataSets (GDS); the marts have no `submission`,
  `gds` or `sMatrix` tables.
- `characteristics_ch1` and `characteristics_ch2` are lists of tag/value
  pairs rather than `;\t`-separated strings, and array columns such as
  `gse.pubmed_id` are lists.
- [`sra_search()`](https://omicidx.github.io/omicidxr/reference/sra_search.md)
  is a case-insensitive pattern match, not SQLite full-text search.
- Pin a monthly release, as this vignette does, where SRAdb code pinned
  a SQLite file.

## Disconnecting

``` r

DBI::dbDisconnect(con)
```
