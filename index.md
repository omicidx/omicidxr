# omicidxr ![](reference/figures/logo.png)

> **Access the OmicIDX omics metadata database from R**

The `omicidxr` package provides a convenient interface to query and
explore the [OmicIDX](https://omicidx.cancerdatasci.org/) metadata
database, a comprehensive resource for omics dataset metadata. Built on
top of [DuckDB](https://duckdb.org/), it enables fast, efficient queries
on large-scale genomics metadata without downloading the entire
database.

## ✨ Features

- 🚀 **Fast queries** powered by DuckDB’s columnar storage
- ☁️ **Cloud-native** access to remote databases via S3-compatible
  storage
- 🔌 **Zero setup** – connect to the public OmicIDX database instantly
- 🧰 **Two interfaces** – use functional-style connections or an R6
  client
- 🔍 **Full SQL support** plus `dplyr`/`dbplyr` integration
- 💾 **In-memory or persistent** – choose your storage backend

## 📦 Installation

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

## 🚀 Quick Start

### Using the R6 Client (Recommended)

The R6 client provides an object-oriented interface with automatic table
discovery:

``` r
library(omicidxr)

# Create a new client (connects to the public database)
oidx <- OmicidxClient$new()

# See what tables are available
oidx$list_tables()

# Access all tables as lazy dplyr references
names(oidx$tbls)

# Or use the tbl() method directly
oidx$tbl("sources.v_src_sra_studies") |>
  dplyr::count(study_type, sort = TRUE) |>
  dplyr::collect()

# Execute raw SQL queries
oidx$query("
    SELECT COUNT(*) as transcriptome_study_count
    FROM sources.v_src_sra_studies
    WHERE study_type = 'Transcriptome Analysis'")
```

### Using Functional Interface

For more control, use the lower-level functional interface:

``` r
library(omicidxr)
library(dplyr)

# Establish connection
con <- connect_omicidx()

# List all available tables
list_tables(con)

# Use dplyr to build queries
tbl(con, "sra.experiment") |>
  filter(library_strategy == "RNA-Seq") |>
  count(platform, sort = TRUE) |>
  collect()

# Execute SQL directly
DBI::dbGetQuery(con, "
  SELECT platform, COUNT(*) as n 
  FROM sra.experiment 
  WHERE library_strategy = 'RNA-Seq'
  GROUP BY platform
  ORDER BY n DESC
")

# Clean up when done
DBI::dbDisconnect(con, shutdown = TRUE)
```

## 📚 Main Functions

| Function / Class                                                                       | Description                                        |
|----------------------------------------------------------------------------------------|----------------------------------------------------|
| `OmicidxClient$new()`                                                                  | Create an R6 client with automatic table discovery |
| [`connect_omicidx()`](https://omicidx.github.io/omicidxr/reference/connect_omicidx.md) | Establish a connection to the OmicIDX database     |
| [`list_tables()`](https://omicidx.github.io/omicidxr/reference/list_tables.md)         | List all available tables in the database          |

### R6 Client Methods

| Method                           | Description                                            |
|----------------------------------|--------------------------------------------------------|
| `$list_tables(schema, database)` | List tables with optional filtering                    |
| `$table_names(schema, database)` | Get fully-qualified table names as a character vector  |
| `$tbl(table_name)`               | Get a lazy `dplyr` table reference                     |
| `$query(sql)`                    | Execute a SQL query and return results                 |
| `$connection()`                  | Access the underlying DuckDB connection                |
| `$tbls`                          | Named list of all table references (populated on init) |

## 🗄️ Database Schemas

The OmicIDX database contains metadata from multiple public omics
repositories:

- **SRA** (Sequence Read Archive) – studies, experiments, samples, runs
- **GEO** (Gene Expression Omnibus) – series, samples, platforms
- **Biosample** – biological sample metadata
- **Additional schemas** – use
  [`list_tables()`](https://omicidx.github.io/omicidxr/reference/list_tables.md)
  to explore

## 🛠️ Advanced Usage

### Persistent Local Database

By default, `omicidxr` uses an in-memory DuckDB instance. For persistent
storage:

``` r
# Create a local database file
client <- OmicidxClient$new(db_path = "~/omicidx_local.duckdb")

# The remote database is still attached, but queries can be cached locally
```

### Direct DBI Operations

Access the underlying connection for full DBI compatibility:

``` r
client <- OmicidxClient$new()
con <- client$connection()

# Use any DBI function
DBI::dbListTables(con)
DBI::dbWriteTable(con, "my_temp_table", data.frame(x = 1:10))
```

## 🤝 Contributing

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
Conduct](https://omicidx.github.io/omicidxr/CODE_OF_CONDUCT.md). By
participating in this project you agree to abide by its terms.

## 📄 License

MIT © Sean Davis

See [LICENSE.md](https://omicidx.github.io/omicidxr/LICENSE.md) for full
license text.

## 🙏 Acknowledgments

- [DuckDB](https://duckdb.org/) for the amazing analytical database
  engine
- The R community for packages like `dplyr`, `dbplyr`, and `DBI`

## 📬 Getting Help

- **Documentation**: <https://omicidx.github.io/omicidxr/> (coming soon)
- **Bug reports**: [GitHub
  Issues](https://github.com/omicidx/omicidxr/issues)
- **Questions**: Open a
  [discussion](https://github.com/omicidx/omicidxr/discussions) or reach
  out via email
