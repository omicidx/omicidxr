# Getting Started with omicidx in R

``` r
library(omicidxr)
```

## omicidxr ![](reference/figures/logo.png)

[![R-CMD-check](https://github.com/omicidx/omicidxr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/omicidx/omicidxr/actions/workflows/R-CMD-check.yaml)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![Project Status:
WIP](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)
[![pkgdown-build](https://github.com/omicidx/omicidxr/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/omicidx/omicidxr/actions/workflows/pkgdown.yaml)

> **Access the OmicIDX omics metadata database from R**

The `omicidxr` package provides a convenient interface to query and
explore the OmicIDX metadata database, a comprehensive resource for
omics dataset metadata. Built on top of [DuckDB](https://duckdb.org/),
it enables fast, efficient queries on large-scale genomics metadata
**without downloading the entire database.**

For users of GEOmetadadb and SRAdb, `omicidxr` offers a modern
alternative with cloud-native access, eliminating the need to manage
large local SQLite files.

### ✨ Features

- 🚀 **Fast queries** powered by DuckDB’s columnar storage
- ☁️ **Cloud-native** access to remote databases via S3-compatible
  storage
- 🔌 **Zero setup** – connect to the public OmicIDX database instantly
- 🧰 **Two interfaces** – use functional-style connections or an R6
  client
- 🔍 **Full SQL support** plus `dplyr`/`dbplyr` integration
- 💾 **In-memory or persistent** – choose your storage backend

### 📦 Installation

You can install the development version of omicidxr from GitHub:

``` r
# install.packages("pak")
pak::pak("omicidx/omicidxr")
```

Or using `remotes`:

``` r
# install.packages("remotes")
remotes::install_github("omicidx/omicidxr")
```

or using ‘BiocManager’:

``` r
# install.packages("BiocManager")
BiocManager::install("omicidx/omicidxr")
```

### 🚀 Quick Start

#### Using the R6 Client (Recommended)

The R6 client provides an object-oriented interface with automatic table
discovery:

``` r
library(omicidxr)

# Create a new client (connects to the public database)
oidx <- OmicidxClient$new()

# See what tables are available
oidx$list_tables()
#> # A tibble: 36 × 6
#>    database schema    name                   column_names column_types temporary
#>    <chr>    <chr>     <chr>                  <list>       <list>       <lgl>    
#>  1 omicidx  geometadb geo_supplemental_files <chr [4]>    <chr [4]>    FALSE    
#>  2 omicidx  geometadb gpl                    <chr [15]>   <chr [15]>   FALSE    
#>  3 omicidx  geometadb gse                    <chr [20]>   <chr [20]>   FALSE    
#>  4 omicidx  geometadb gse_gpl                <chr [2]>    <chr [2]>    FALSE    
#>  5 omicidx  geometadb gse_gsm                <chr [2]>    <chr [2]>    FALSE    
#>  6 omicidx  geometadb gsm                    <chr [31]>   <chr [31]>   FALSE    
#>  7 omicidx  main      src_bioprojects        <chr [9]>    <chr [9]>    FALSE    
#>  8 omicidx  main      src_biosamples         <chr [19]>   <chr [19]>   FALSE    
#>  9 omicidx  main      src_geo_platforms      <chr [20]>   <chr [20]>   FALSE    
#> 10 omicidx  main      src_geo_samples        <chr [26]>   <chr [26]>   FALSE    
#> # ℹ 26 more rows

# Usse the tbl() method to get dplyyr table references
oidx$tbl("src_sra_studies") |>
  dplyr::count(study_type, sort = TRUE) |>
  dplyr::collect()
#> # A tibble: 12 × 2
#>    study_type                      n
#>    <chr>                       <dbl>
#>  1 "Other"                    382944
#>  2 "Whole Genome Sequencing"  122829
#>  3 "Transcriptome Analysis"   116357
#>  4 "Metagenomics"              68586
#>  5 "Population Genomics"         834
#>  6 "Epigenetics"                 694
#>  7 "Cancer Genomics"             431
#>  8 "Exome Sequencing"            372
#>  9 "Pooled Clone Sequencing"      31
#> 10 "Synthetic Genomics"           12
#> 11 "Transcriptome Sequencing"      2
#> 12 "Whole Genome Sequencing "      1

# Execute raw SQL queries
oidx$query("
    SELECT COUNT(*) as transcriptome_study_count
    FROM src_sra_studies
    WHERE study_type = 'Transcriptome Analysis'")
#>   transcriptome_study_count
#> 1                    116357
```

#### Using Functional Interface

For more control, use the lower-level functional interface:

``` r
library(omicidxr)
library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union

# Establish connection
con <- connect_omicidx()

# List all available tables
list_tables(con)
#> # A tibble: 36 × 6
#>    database schema    name                   column_names column_types temporary
#>    <chr>    <chr>     <chr>                  <list>       <list>       <lgl>    
#>  1 omicidx  geometadb geo_supplemental_files <chr [4]>    <chr [4]>    FALSE    
#>  2 omicidx  geometadb gpl                    <chr [15]>   <chr [15]>   FALSE    
#>  3 omicidx  geometadb gse                    <chr [20]>   <chr [20]>   FALSE    
#>  4 omicidx  geometadb gse_gpl                <chr [2]>    <chr [2]>    FALSE    
#>  5 omicidx  geometadb gse_gsm                <chr [2]>    <chr [2]>    FALSE    
#>  6 omicidx  geometadb gsm                    <chr [31]>   <chr [31]>   FALSE    
#>  7 omicidx  main      src_bioprojects        <chr [9]>    <chr [9]>    FALSE    
#>  8 omicidx  main      src_biosamples         <chr [19]>   <chr [19]>   FALSE    
#>  9 omicidx  main      src_geo_platforms      <chr [20]>   <chr [20]>   FALSE    
#> 10 omicidx  main      src_geo_samples        <chr [26]>   <chr [26]>   FALSE    
#> # ℹ 26 more rows

# Use dplyr to build queries
dplyr::tbl(con, "src_sra_experiments") |>
  dplyr::filter(library_strategy == "RNA-Seq") |>
  dplyr::count(platform, sort = TRUE) |>
  dplyr::collect()
#> # A tibble: 17 × 2
#>    platform                n
#>    <chr>               <dbl>
#>  1 ILLUMINA          6113098
#>  2 OXFORD_NANOPORE    111163
#>  3 BGISEQ              96331
#>  4 DNBSEQ              86509
#>  5 ION_TORRENT         27192
#>  6 PACBIO_SMRT         13230
#>  7 ABI_SOLID           12510
#>  8 LS454                7071
#>  9 CAPILLARY            4422
#> 10 ELEMENT              4173
#> 11 COMPLETE_GENOMICS    1058
#> 12 HELICOS               704
#> 13 VELA_DIAGNOSTICS      595
#> 14 GENEMIND              242
#> 15 ULTIMA                233
#> 16 TAPESTRI               45
#> 17 GENAPSYS               34

# Execute SQL directly
DBI::dbGetQuery(con, "
  SELECT platform, COUNT(*) as n 
  FROM src_sra_experiments
  WHERE library_strategy = 'RNA-Seq'
  GROUP BY platform
  ORDER BY n DESC
")
#>             platform       n
#> 1           ILLUMINA 6113098
#> 2    OXFORD_NANOPORE  111163
#> 3             BGISEQ   96331
#> 4             DNBSEQ   86509
#> 5        ION_TORRENT   27192
#> 6        PACBIO_SMRT   13230
#> 7          ABI_SOLID   12510
#> 8              LS454    7071
#> 9          CAPILLARY    4422
#> 10           ELEMENT    4173
#> 11 COMPLETE_GENOMICS    1058
#> 12           HELICOS     704
#> 13  VELA_DIAGNOSTICS     595
#> 14          GENEMIND     242
#> 15            ULTIMA     233
#> 16          TAPESTRI      45
#> 17          GENAPSYS      34

# Clean up when done
DBI::dbDisconnect(con, shutdown = TRUE)
```

### 📚 Main Functions

| Function / Class                                                                       | Description                                        |
|----------------------------------------------------------------------------------------|----------------------------------------------------|
| `OmicidxClient$new()`                                                                  | Create an R6 client with automatic table discovery |
| [`connect_omicidx()`](https://omicidx.github.io/omicidxr/reference/connect_omicidx.md) | Establish a connection to the OmicIDX database     |
| [`list_tables()`](https://omicidx.github.io/omicidxr/reference/list_tables.md)         | List all available tables in the database          |

#### R6 Client Methods

| Method                           | Description                                            |
|----------------------------------|--------------------------------------------------------|
| `$list_tables(schema, database)` | List tables with optional filtering                    |
| `$table_names(schema, database)` | Get fully-qualified table names as a character vector  |
| `$tbl(table_name)`               | Get a lazy `dplyr` table reference                     |
| `$query(sql)`                    | Execute a SQL query and return results                 |
| `$connection()`                  | Access the underlying DuckDB connection                |
| `$tbls`                          | Named list of all table references (populated on init) |

### 🗄️ Database Schemas

The OmicIDX database contains metadata from multiple public omics
repositories:

- **SRA** (Sequence Read Archive) – studies, experiments, samples, runs
- **GEO** (Gene Expression Omnibus) – series, samples, platforms
- **Biosample** – biological sample metadata
- **Additional schemas** – use
  [`list_tables()`](https://omicidx.github.io/omicidxr/reference/list_tables.md)
  to explore

### 🛠️ Advanced Usage

#### Persistent Local Database

By default, `omicidxr` uses an in-memory DuckDB instance. For persistent
storage:

``` r
# Create a local database file
client <- OmicidxClient$new(db_path = "~/omicidx_local.duckdb")

# The remote database is still attached, but queries can be cached locally
```

### 🤝 Contributing

Contributions are welcome! Here’s how you can help:

1.  **Report bugs** – [Open an
    issue](https://github.com/omicidx/omicidxr/issues) with a
    reproducible example
2.  **Suggest features** – Share your ideas in the [issue
    tracker](https://github.com/omicidx/omicidxr/issues)
3.  **Submit PRs** – Fork, create a feature branch, and submit a pull
    request
4.  **Improve docs** – Help make the documentation clearer

Please note that this project is released with a [Contributor Code of
Conduct](https://omicidx.github.io/omicidxr/articles/CODE_OF_CONDUCT.md).
By participating in this project you agree to abide by its terms.

### 📄 License

MIT © Sean Davis

See [LICENSE.md](https://omicidx.github.io/omicidxr/articles/LICENSE.md)
for full license text.

### 🙏 Acknowledgments

- [DuckDB](https://duckdb.org/) for the amazing analytical database
  engine
- The R community for packages like `dplyr`, `dbplyr`, and `DBI`

### 📬 Getting Help

- **Documentation**: <https://omicidx.github.io/omicidxr/>
- **Bug reports**: [GitHub
  Issues](https://github.com/omicidx/omicidxr/issues)
- **Questions**: Open a
  [discussion](https://github.com/omicidx/omicidx/discussions) or reach
  out via email
