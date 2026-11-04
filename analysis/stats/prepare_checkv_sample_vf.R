###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   prepare_checkv_sample_vf.R
###############################################################################


prepare.checkv.sample.vf <- function(data) {
  required.columns <- c(
    "checkv.filter", "genome.id", "category", "origin", "sample",
    "total.bacterial.orfs", "qualifying.vf.orfs", "vfdb_version", "orf_pool"
  )
  if (!all(required.columns %in% names(data)) || nrow(data) == 0L ||
      anyNA(data[required.columns])) {
    stop("Missing CheckV sample VF inputs")
  }
  if (anyDuplicated(data[c("checkv.filter", "genome.id")])) {
    stop("Duplicate CheckV genome keys")
  }
  if (any(data$checkv.filter != "conservative")) {
    stop("Sample prevalence requires conservative trimming only")
  }
  if (any(data$vfdb_version != "VFDB_setB") ||
      any(data$orf_pool != "all_bacterial_prokka_cds")) {
    stop("Sample prevalence requires full-pool VFDB set B provenance")
  }
  counts <- data[c("total.bacterial.orfs", "qualifying.vf.orfs")]
  if (any(!vapply(counts, is.numeric, logical(1))) ||
      any(!is.finite(as.matrix(counts))) ||
      any(counts < 0 | counts != floor(as.matrix(counts))) ||
      any(data$qualifying.vf.orfs > data$total.bacterial.orfs)) {
    stop("Invalid integer CheckV ORF counts")
  }
  if (any(!data$category %in% c("pal", "pre", "ind")) ||
      any(!grepl("^[A-Z]{3}$", data$origin)) ||
      any(!nzchar(trimws(data$sample)))) {
    stop("Invalid CheckV sample identifiers")
  }

  # sum counts across all genomes, including zero-hit and zero-ORF genomes.
  samples <- data %>%
    mutate(sample.id = paste0(category, ".", origin, "_", sample)) %>%
    group_by(checkv.filter, sample.id, sample, category, origin,
             vfdb_version, orf_pool) %>%
    summarise(
      genome.count = n(),
      total.bacterial.orfs = sum(total.bacterial.orfs),
      qualifying.vf.orfs = sum(qualifying.vf.orfs),
      .groups = "drop"
    ) %>%
    filter(
      !sample.id %in% c("pal.ENG_LG4560.69", "pal.AUT_2612"),
      total.bacterial.orfs > 5L
    ) %>%
    mutate(vf.orf.prevalence = qualifying.vf.orfs / total.bacterial.orfs)
  if (anyDuplicated(samples$sample.id)) {
    stop("Canonical CheckV sample IDs are not unique")
  }
  return(samples)
}
