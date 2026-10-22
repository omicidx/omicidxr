# Helpers in the style of the SRAdb and GEOmetadb packages, over the sradb
# and geometadb schemas. Each is one query returning a tibble.

#' @importFrom dplyr .data
NULL

accession_patterns <- c(
  study = "^[SED]RP[0-9]+$",
  sample = "^[SED]RS[0-9]+$",
  experiment = "^[SED]RX[0-9]+$",
  run = "^[SED]RR[0-9]+$",
  biosample = "^SAM[NED][A-Z]?[0-9]+$",
  bioproject = "^PRJ[NED][A-Z][0-9]+$",
  gse = "^GSE[0-9]+$",
  gsm = "^GSM[0-9]+$",
  gpl = "^GPL[0-9]+$"
)
geo_types <- c("gse", "gsm", "gpl")

# The accession type ("study", "gsm", ...) of each element of `x`.
accession_type <- function(x) {
  type <- rep(NA_character_, length(x))
  for (t in names(accession_patterns)) type[grepl(accession_patterns[[t]], x)] <- t
  if (anyNA(type)) {
    stop("Unrecognised accession(s): ",
         paste(utils::head(x[is.na(type)], 5), collapse = ", "), call. = FALSE)
  }
  type
}

check_accessions <- function(x, types = names(accession_patterns)) {
  stopifnot(is.character(x), length(x) > 0L)
  x <- unique(toupper(x))
  bad <- !accession_type(x) %in% types
  if (any(bad)) {
    stop("Expected ", paste(types, collapse = "/"), " accessions, not: ",
         paste(utils::head(x[bad], 5), collapse = ", "), call. = FALSE)
  }
  x
}

# One row per SRA run with its accessions; experiments are the bridge to GEO.
sra_links <- function(con) {
  dplyr::tbl(con, I("sradb.sra")) |>
    dplyr::select(run = "run_accession", experiment = "experiment_accession",
                  sample = "sample_accession", study = "study_accession",
                  biosample = "biosample_accession",
                  bioproject = "bioproject_accession")
}

geo_links <- function(con) {
  dplyr::tbl(con, I("geometadb.gsm")) |>
    dplyr::select("gsm", "gpl", experiment = "sra_experiment") |>
    dplyr::left_join(dplyr::tbl(con, I("geometadb.gse_gsm")), by = "gsm")
}

#' Convert between SRA, GEO, BioSample and BioProject accessions
#'
#' The successor to `SRAdb::sraConvert()` and `GEOmetadb::geoConvert()`.
#' Accessions of any supported type, mixed freely, are mapped to the
#' requested types.
#'
#' Supported types: SRA `study` (SRP/ERP/DRP), `sample` (SRS/ERS/DRS),
#' `experiment` (SRX/ERX/DRX) and `run` (SRR/ERR/DRR); `biosample`
#' (SAMN/SAMEA/SAMD); `bioproject` (PRJNA/PRJEB/PRJDB); and GEO `gse`,
#' `gsm` and `gpl`. SRA accessions are linked through runs
#' (`sradb.sra`), so experiments without runs are not found, and GEO
#' samples link to SRA through their SRA experiment. Converting a GPL
#' returns every sample on that platform, which can be large.
#'
#' @param con A connection from [omicidx_connect()], or an [omicidx_db()].
#' @param in_acc character. Accessions to convert.
#' @param out_type character. Accession types to return.
#'
#' @return A tibble with one column per input type present and per
#'   `out_type`, with one row per distinct combination. `NA` where an
#'   accession has no link of that type.
#'
#' @examples
#' \donttest{
#' con <- omicidx_connect()
#' sra_convert(con, "SRP000001")
#' geo_convert(con, "GSE164073", c("gsm", "run"))
#' DBI::dbDisconnect(con)
#' }
#'
#' @export
sra_convert <- function(con,
                        in_acc,
                        out_type = c("study", "sample", "experiment", "run")) {
  con <- omicidx_con(con)
  out_type <- match.arg(out_type, names(accession_patterns), several.ok = TRUE)
  in_acc <- check_accessions(in_acc)
  types <- accession_type(in_acc)
  pieces <- lapply(unique(types), function(type) {
    ids <- in_acc[types == type]
    cols <- union(type, out_type)
    if (type %in% geo_types) {
      links <- geo_links(con)
      other <- if (any(!cols %in% c(geo_types, "experiment"))) sra_links(con)
    } else {
      links <- sra_links(con)
      other <- if (any(cols %in% geo_types)) geo_links(con)
    }
    links <- dplyr::filter(links, .data[[type]] %in% !!ids)
    if (!is.null(other)) links <- dplyr::left_join(links, other, by = "experiment")
    links |>
      dplyr::select(dplyr::all_of(cols)) |>
      dplyr::distinct() |>
      dplyr::collect()
  })
  out <- dplyr::bind_rows(pieces)
  out[intersect(names(accession_patterns), names(out))]
}

#' @rdname sra_convert
#' @param in_list character. Accessions to convert, as in
#'   `GEOmetadb::geoConvert()`.
#' @export
geo_convert <- function(con, in_list, out_type = c("gse", "gpl", "gsm")) {
  sra_convert(con, in_list, out_type)
}

#' SRA runs for studies, experiments, samples or GEO accessions
#'
#' The runs behind each accession, with the fields needed to choose and
#' download them: pass `run_accession` to `prefetch` or `fasterq-dump`
#' from the SRA Toolkit.
#'
#' @inheritParams sra_convert
#' @param in_acc character. Accessions of any type [sra_convert()]
#'   supports, for example studies, experiments or GSEs.
#'
#' @return A tibble with one row per run: its accessions, `spots`,
#'   `bases`, library strategy, source, selection and layout, platform,
#'   instrument model and organism.
#'
#' @examples
#' \donttest{
#' con <- omicidx_connect()
#' sra_runs(con, "SRP000001")
#' DBI::dbDisconnect(con)
#' }
#'
#' @export
sra_runs <- function(con, in_acc) {
  con <- omicidx_con(con)
  in_acc <- check_accessions(in_acc)
  types <- accession_type(in_acc)
  experiments <- in_acc[types == "experiment"]
  if (any(types %in% geo_types)) {
    geo <- sra_convert(con, in_acc[types %in% geo_types], "experiment")
    experiments <- union(experiments, geo$experiment[!is.na(geo$experiment)])
  }
  by_column <- c(experiment = "experiment_accession", study = "study_accession",
                 sample = "sample_accession", run = "run_accession",
                 biosample = "biosample_accession",
                 bioproject = "bioproject_accession")
  ids <- split(in_acc[!types %in% geo_types], types[!types %in% geo_types])
  ids$experiment <- experiments
  ids <- ids[lengths(ids) > 0L]
  if (length(ids) == 0L) ids <- list(experiment = character())
  pieces <- lapply(names(ids), function(type) {
    dplyr::tbl(con, I("sradb.sra")) |>
      dplyr::filter(.data[[by_column[[type]]]] %in% !!ids[[type]]) |>
      dplyr::select(
        "run_accession", "experiment_accession", "sample_accession",
        "study_accession", "biosample_accession", "bioproject_accession",
        "spots", "bases", "library_strategy", "library_source",
        "library_selection", "library_layout", "platform", "instrument_model",
        "scientific_name", "taxon_id", "experiment_title"
      ) |>
      dplyr::collect()
  })
  dplyr::distinct(dplyr::bind_rows(pieces))
}

#' Samples and platforms of GEO series
#'
#' The GEOmetadb join of `gse_gsm`, `gsm` and `gpl` as one call.
#'
#' @inheritParams sra_convert
#' @param gse character. GEO series accessions.
#'
#' @return A tibble with one row per series and sample: `gse`, `gsm`,
#'   sample `title`, `gpl`, `platform_title`, organism, source,
#'   molecule, sample `type`, `library_source`, `biosample` and
#'   `sra_experiment`.
#'
#' @examples
#' \donttest{
#' con <- omicidx_connect()
#' geo_samples(con, "GSE164073")
#' DBI::dbDisconnect(con)
#' }
#'
#' @export
geo_samples <- function(con, gse) {
  con <- omicidx_con(con)
  gse <- check_accessions(gse, "gse")
  platforms <- dplyr::tbl(con, I("geometadb.gpl")) |>
    dplyr::select("gpl", platform_title = "title")
  dplyr::tbl(con, I("geometadb.gse_gsm")) |>
    dplyr::filter(.data$gse %in% !!gse) |>
    dplyr::inner_join(dplyr::tbl(con, I("geometadb.gsm")), by = "gsm") |>
    dplyr::left_join(platforms, by = "gpl") |>
    dplyr::select(
      "gse", "gsm", "title", "gpl", "platform_title", "organism_ch1",
      "source_name_ch1", "molecule_ch1", "type", "library_source",
      "biosample", "sra_experiment"
    ) |>
    dplyr::arrange(.data$gse, .data$gsm) |>
    dplyr::collect()
}

#' Characteristics of GEO samples
#'
#' The `characteristics_ch1` and `characteristics_ch2` tag/value pairs
#' of each sample, one row per pair. In GEOmetadb these were one
#' `;\t`-separated string per channel.
#'
#' @inheritParams sra_convert
#' @param gsm character. GEO sample accessions.
#'
#' @return A tibble with columns `gsm`, `channel` (1 or 2), `tag` and
#'   `value`.
#'
#' @examples
#' \donttest{
#' con <- omicidx_connect()
#' geo_characteristics(con, c("GSM4996084", "GSM4996085"))
#' DBI::dbDisconnect(con)
#' }
#'
#' @export
geo_characteristics <- function(con, gsm) {
  con <- omicidx_con(con)
  gsm <- check_accessions(gsm, "gsm")
  samples <- dplyr::tbl(con, I("geometadb.gsm")) |>
    dplyr::filter(.data$gsm %in% !!gsm) |>
    dplyr::select("gsm", "characteristics_ch1", "characteristics_ch2") |>
    dplyr::collect()
  long <- function(channel) {
    pairs <- samples[[paste0("characteristics_ch", channel)]]
    n <- vapply(pairs, function(p) if (is.null(p)) 0L else nrow(p), integer(1))
    tibble::tibble(
      gsm = rep(samples$gsm, n),
      channel = rep(channel, sum(n)),
      tag = unlist(lapply(pairs, `[[`, "tag")),
      value = unlist(lapply(pairs, `[[`, "value"))
    )
  }
  out <- dplyr::bind_rows(long(1L), long(2L))
  out[order(out$gsm, out$channel), ]
}

#' Search SRA studies or GEO series by text
#'
#' Case-insensitive substring search (SQL `ILIKE`) over SRA study titles
#' and abstracts, or GEO series titles and summaries. The successor to
#' `SRAdb::getSRA()` for finding studies; it is a plain pattern match,
#' not a ranked full-text search.
#'
#' @inheritParams sra_convert
#' @param query character(1). Text to find. `%` matches any run of
#'   characters and `_` any single character, so `"single cell%glioma"`
#'   finds both phrases in that order.
#' @param limit integer(1). Maximum number of rows to return.
#'
#' @return A tibble of matching studies (`sra_search()`: from
#'   `sradb.study`) or series (`geo_search()`: from `geometadb.gse`).
#'
#' @examples
#' \donttest{
#' con <- omicidx_connect()
#' sra_search(con, "single cell%glioma", limit = 5)
#' geo_search(con, "glioblastoma", limit = 5)
#' DBI::dbDisconnect(con)
#' }
#'
#' @export
sra_search <- function(con, query, limit = 100L) {
  text_search(con, query, limit, "
    SELECT study_accession, study_title, study_type, study_abstract,
           center_name, bioproject_accession, geo_accession
    FROM sradb.study
    WHERE study_title ILIKE $1 OR study_abstract ILIKE $1
    LIMIT $2")
}

#' @rdname sra_search
#' @export
geo_search <- function(con, query, limit = 100L) {
  text_search(con, query, limit, "
    SELECT gse, title, type, submission_date, summary, bioprojects, sra_studies
    FROM geometadb.gse
    WHERE title ILIKE $1 OR summary ILIKE $1
    LIMIT $2")
}

text_search <- function(con, query, limit, sql) {
  con <- omicidx_con(con)
  stopifnot(is.character(query), length(query) == 1L, !is.na(query))
  limit <- as.integer(limit)
  stopifnot(length(limit) == 1L, !is.na(limit), limit >= 0L)
  tibble::as_tibble(DBI::dbGetQuery(
    con, sql, params = list(paste0("%", query, "%"), limit)
  ))
}
