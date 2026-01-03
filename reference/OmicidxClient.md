# Omicidx DuckDB Client (R6)

Omicidx DuckDB Client (R6)

Omicidx DuckDB Client (R6)

## Details

This is the main class for interacting with the OmicIDX data resource.
It provides methods for connecting to the Omicidx DuckDB database,
listing tables, retrieving `dplyr` table references, and executing SQL
queries.

The `OmicidxClient` class uses R6 to encapsulate the functionality for
connecting to and querying the Omicidx DuckDB database. It provides a
user-friendly interface for accessing the data stored in the database.

A typical workflow will involve:

- Creating a new `OmicidxClient` object using `OmicidxClient$new()`.

- Listing available tables using
  [`list_tables()`](https://omicidx.github.io/omicidxr/reference/list_tables.md).

- Accessing specific tables using
  [`tbl()`](https://dplyr.tidyverse.org/reference/tbl.html) or by
  referencing tables in the `tbls` field.

If you need to execute custom SQL queries, you can use the `query()`
method.

The underlying DuckDB database is actually stored on an S3-compatible
object store, but the client abstracts away the details of connecting to
the database. The database does not need to be downloaded locally; the
data are also stored in the cloud and queried remotely via DuckDB.

If you want to persist the DuckDB instance locally (e.g., to cache query
results), you can provide a local file path when creating the
`OmicidxClient` object.

## Public fields

- `con`:

  A DuckDB connection object.

- `tbls`:

  A named list of lazy `dplyr` table references. Populated during
  initialization using `OmicidxClient$table_names()` and
  `OmicidxClient$tbl()`.

## Methods

### Public methods

- [`OmicidxClient$new()`](#method-OmicidxClient-new)

- [`OmicidxClient$connection()`](#method-OmicidxClient-connection)

- [`OmicidxClient$list_tables()`](#method-OmicidxClient-list_tables)

- [`OmicidxClient$table_names()`](#method-OmicidxClient-table_names)

- [`OmicidxClient$tbl()`](#method-OmicidxClient-tbl)

- [`OmicidxClient$query()`](#method-OmicidxClient-query)

- [`OmicidxClient$describe_table()`](#method-OmicidxClient-describe_table)

- [`OmicidxClient$execute()`](#method-OmicidxClient-execute)

- [`OmicidxClient$clone()`](#method-OmicidxClient-clone)

------------------------------------------------------------------------

### Method `new()`

Create a new OmicidxClient.

#### Usage

    OmicidxClient$new(db_path = ":memory:")

#### Arguments

- `db_path`:

  character(1) Path passed to DuckDB as `dbdir`. The default is to use
  `":memory:"`.

#### Returns

A new `OmicidxClient` object.

------------------------------------------------------------------------

### Method `connection()`

Get the underlying DuckDB connection.

#### Usage

    OmicidxClient$connection()

#### Returns

A DuckDB connection object.

------------------------------------------------------------------------

### Method [`list_tables()`](https://omicidx.github.io/omicidxr/reference/list_tables.md)

List tables in the Omicidx database.

#### Usage

    OmicidxClient$list_tables(schema = NA, database = NA)

#### Arguments

- `schema`:

  character(1) Schema name to filter by. Use `NA` (default) for all
  schemas.

- `database`:

  character(1) Database name to filter by. Use `NA` (default) for all
  databases.

#### Returns

A tibble containing information about tables in the database.

------------------------------------------------------------------------

### Method `table_names()`

Get fully qualified table names as a named character vector.

#### Usage

    OmicidxClient$table_names(schema = NA, database = NA)

#### Arguments

- `schema`:

  character(1) Schema name to filter by. Use `NA` (default) for all
  schemas.

- `database`:

  character(1) Database name to filter by. Use `NA` (default) for all
  databases.

#### Returns

A named character vector of fully qualified table names.

------------------------------------------------------------------------

### Method [`tbl()`](https://dplyr.tidyverse.org/reference/tbl.html)

Get a `dplyr` table reference for a specific table.

#### Usage

    OmicidxClient$tbl(table_name)

#### Arguments

- `table_name`:

  character(1) A table name (optionally schema-qualified) to reference.

#### Returns

A `dplyr` table reference.

------------------------------------------------------------------------

### Method `query()`

Execute an arbitrary SQL query (as a string) against the database.

#### Usage

    OmicidxClient$query(sql)

#### Arguments

- `sql`:

  character(1) A SQL string to execute via
  [`DBI::dbGetQuery()`](https://dbi.r-dbi.org/reference/dbGetQuery.html).

#### Returns

A data frame containing the query result.

------------------------------------------------------------------------

### Method `describe_table()`

Describe the schema of a specific table using the duckdb DESCRIBE
command.

#### Usage

    OmicidxClient$describe_table(table_name)

#### Arguments

- `table_name`:

  character(1) A table name (optionally schema-qualified) to describe.

#### Returns

A data frame containing the table schema.

------------------------------------------------------------------------

### Method `execute()`

Execute a SQL command against the database.

#### Usage

    OmicidxClient$execute(sql)

#### Arguments

- `sql`:

  character(1) A SQL string to execute via
  [`DBI::dbExecute()`](https://dbi.r-dbi.org/reference/dbExecute.html).

#### Returns

An integer indicating the number of rows affected.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    OmicidxClient$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
oidx <- OmicidxClient$new()
#> Error in loadNamespace(x): there is no package called ‘dbplyr’
oidx$list_tables()
#> Error: object 'oidx' not found
# tbl_ref <- oidx$tbl("some_table")
# oidx$query("SELECT * FROM some_table LIMIT 5")

# Get all table names
oidx$table_names()
#> Error: object 'oidx' not found

# Get a description of a specific table
# This is the table "schema"
oidx$describe_table("sources.v_src_sra_studies")
#> Error: object 'oidx' not found

# create a table of SRA runs published per year
runs_by_year <- oidx$tbls$sources.v_src_sra_accessions |>
 dplyr::filter(Type == "RUN") |>
 dplyr::mutate(Year = dplyr::sql("EXTRACT(YEAR FROM Published)")) |>
 dplyr::group_by(Year) |>
 dplyr::summarise(RunCount = dplyr::n())
#> Error: object 'oidx' not found
```
