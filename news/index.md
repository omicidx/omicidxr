# Changelog

## omicidxr 0.99.0

- Bioconductor submission.
- Network reads are bounded:
  [`omicidx_connect()`](https://seandavi.github.io/omicidxr/reference/omicidx_connect.md)
  sets DuckDB’s `http_timeout` (30 s) and retries each request up to 4
  times with backoff, including on HTTP 429, and a failed connect names
  the release URL and suggests what to do
  ([\#16](https://github.com/seandavi/omicidxr/issues/16)).
  [`omicidx_download()`](https://seandavi.github.io/omicidxr/reference/omicidx_download.md)
  retries for up to 6 minutes so a copy of a monthly release waits out
  HuggingFace’s rate limit.
- Monthly releases use `HF_TOKEN`, if set, for HuggingFace’s higher
  signed-in rate limit.
  [`?omicidx_connect`](https://seandavi.github.io/omicidxr/reference/omicidx_connect.md),
  the README and the vignette recommend querying `"latest"` or dated
  builds in place and downloading monthly releases with
  [`omicidx_download()`](https://seandavi.github.io/omicidxr/reference/omicidx_download.md).
- The vignette and tests use `"latest"` rather than HuggingFace, so
  builds do not fail on HuggingFace’s rate limit.
- `omicidx_connect(version)` opens a DuckDB connection to an OmicIDX
  release: `"latest"`, a dated nightly build `"YYYY-MM-DD"` or a monthly
  release `"YYYY-MM"`. Nothing is downloaded up front, and DuckDB
  extensions are cached in `tools::R_user_dir("omicidxr", "cache")`
  rather than `~/.duckdb`.
- [`omicidx_release()`](https://seandavi.github.io/omicidxr/reference/omicidx_release.md)
  reports a connection’s release and its provenance from
  `manifest.json`.
- `omicidx_download(version, path, tables)` copies a release, or only
  the chosen tables or schemas, into a local DuckDB file for offline
  use, checked against `manifest.json` row counts. It reports the size
  of the Parquet it will read before it starts.
- [`omicidx_tables()`](https://seandavi.github.io/omicidxr/reference/omicidx_tables.md),
  [`omicidx_describe()`](https://seandavi.github.io/omicidxr/reference/omicidx_describe.md)
  and
  [`omicidx_db()`](https://seandavi.github.io/omicidxr/reference/omicidx_db.md)
  list, describe and wrap the release’s tables as tab-completable lazy
  `dplyr` tables.
- SRAdb and GEOmetadb successors:
  [`sra_convert()`](https://seandavi.github.io/omicidxr/reference/sra_convert.md),
  [`geo_convert()`](https://seandavi.github.io/omicidxr/reference/sra_convert.md),
  [`sra_runs()`](https://seandavi.github.io/omicidxr/reference/sra_runs.md),
  [`geo_samples()`](https://seandavi.github.io/omicidxr/reference/geo_samples.md),
  [`geo_characteristics()`](https://seandavi.github.io/omicidxr/reference/geo_characteristics.md),
  [`sra_search()`](https://seandavi.github.io/omicidxr/reference/sra_search.md)
  and
  [`geo_search()`](https://seandavi.github.io/omicidxr/reference/sra_search.md).
