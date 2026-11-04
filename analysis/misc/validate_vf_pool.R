###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   validate_vf_pool.R
###############################################################################


# validate the regenerated full bacterial Prokka denominator contract.
validate.vf.pool <- function(data, version) {
  required.columns <- c("orf_pool", "vfdb_version")
  if (!all(required.columns %in% names(data)) ||
      anyNA(data[required.columns]) ||
      any(data$orf_pool != "all_bacterial_prokka_cds") ||
      any(data$vfdb_version != version)) {
    stop("Regenerate full-pool VFDB tables for ", version)
  }
  if ("total_bacterial_orfs" %in% names(data)) {
    totals <- data$total_bacterial_orfs
    hits <- data$qualifying_vf_orfs
    expected <- ifelse(totals > 0, hits / totals, NA_real_)
    observed <- data$vf_orf_prevalence
    if (anyNA(totals) || anyNA(hits) ||
        any(!is.finite(totals) | !is.finite(hits)) ||
        any(totals < 0 | hits < 0 | hits > totals) ||
        any(totals != floor(totals) | hits != floor(hits)) ||
        any(is.na(observed) != is.na(expected)) ||
        any(abs(observed - expected) > 1e-12, na.rm = TRUE)) {
      stop("Invalid full-pool VFDB counts or prevalence")
    }
  }
  return(invisible(data))
}
