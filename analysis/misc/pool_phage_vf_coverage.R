# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# ___
# pool_phage_vf_coverage.R
# ______________________________________________________________________________
# pattern: Functional Core


# Pool covered and total phage-contig bases within each sample.
pool.phage.vf.coverage <- function(data, exclusions = character()) {
  required.columns <- c(
    "sample", "contig_length", "vf_covered_bases"
  )
  missing.columns <- setdiff(required.columns, colnames(data))
  if (length(missing.columns) > 0) {
    stop(
      "Phage VF table is missing coverage columns: ",
      paste(missing.columns, collapse = ", ")
    )
  }
  if (any(data$contig_length <= 0) ||
      any(data$vf_covered_bases < 0) ||
      any(data$vf_covered_bases > data$contig_length)) {
    stop("Phage VF table violates coverage count bounds")
  }

  sample.coverage <- data %>%
    filter(!sample %in% exclusions) %>%
    group_by(sample) %>%
    summarise(
      sample.vf.covered.bases = sum(vf_covered_bases),
      sample.phage.bases = sum(contig_length),
      .groups = "drop"
    ) %>%
    mutate(
      sample.vf.contig.coverage =
        sample.vf.covered.bases / sample.phage.bases
    )

  return(sample.coverage)
}
