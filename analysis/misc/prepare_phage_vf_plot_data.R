###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   prepare_phage_vf_plot_data.R
###############################################################################


# validate the collector contract and retain two-level lifestyle plot rows.
prepare.phage.vf.plot.data <- function(data) {
  required.columns <- c(
    "category", "origin", "sample", "contig_id", "lifestyle",
    "contig_length", "total_bacterial_orfs", "qualifying_vf_orfs",
    "vf_orf_prevalence", "vf_covered_bases", "vf_contig_coverage"
  )
  missing.columns <- setdiff(required.columns, colnames(data))
  if (length(missing.columns) > 0) {
    stop(
      "Phage VF table is missing required columns: ",
      paste(missing.columns, collapse = ", ")
    )
  }
  if (anyDuplicated(data[c("sample", "contig_id")]) > 0) {
    stop("Phage VF table has duplicate sample + contig_id keys")
  }
  if (any(!data$category %in% c("pal", "pre", "ind"))) {
    stop("Phage VF table has an unsupported sample category")
  }
  if (any(data$contig_length <= 0) ||
      any(data$total_bacterial_orfs < 0) ||
      any(data$qualifying_vf_orfs < 0) ||
      any(data$qualifying_vf_orfs > data$total_bacterial_orfs) ||
      any(data$vf_covered_bases < 0) ||
      any(data$vf_covered_bases > data$contig_length) ||
      any(!is.na(data$vf_orf_prevalence) &
          (data$vf_orf_prevalence < 0 | data$vf_orf_prevalence > 1)) ||
      any(data$vf_contig_coverage < 0 | data$vf_contig_coverage > 1) ||
      any(is.na(data$vf_orf_prevalence) !=
          (data$total_bacterial_orfs == 0))) {
    stop("Phage VF table violates count or proportion bounds")
  }

  expected.origins <- c(
    "AUT", "AWC", "BMS", "ZAF", "ZAP", "FJI", "MDG", "MEX",
    "NPL", "PER", "TZA", "CHN", "DNK", "ESP", "USA"
  )
  origin.levels <- c(
    expected.origins,
    sort(setdiff(unique(data$origin), expected.origins))
  )

  plot.data <- data %>%
    filter(lifestyle %in% c("Lytic", "Temperate")) %>%
    transmute(
      category = factor(category, levels = c("pal", "pre", "ind")),
      origin = factor(origin, levels = origin.levels),
      sample = sample,
      contig.id = contig_id,
      lifestyle = factor(lifestyle, levels = c("Lytic", "Temperate")),
      vf.orf.prevalence = vf_orf_prevalence,
      vf.contig.coverage = vf_contig_coverage
    )

  return(plot.data)
}
