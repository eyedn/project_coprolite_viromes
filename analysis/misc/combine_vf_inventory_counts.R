# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# ___
# combine_vf_inventory_counts.R
# ______________________________________________________________________________
# Each inventory row is one ORF with its best qualifying hit, if present.
combine.vf.inventory.counts <- function(counts, chunk, samples) {
  chunk.counts <- chunk %>%
    filter(sample %in% samples, !is.na(vf_id), vf_id != "") %>%
    count(vf_id, sample)
  bind_rows(counts, chunk.counts) %>%
    group_by(vf_id, sample) %>%
    summarise(n = sum(n), .groups = "drop")
}
