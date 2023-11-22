###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   format_vf_counts.R
###############################################################################


format_vf_counts <- function(data, vf_ref) {
  data[, "cat"] <- NA
  profiles <- rownames(data)
  
  # identify which category each profile belongs to
  for (i in seq_len(nrow(data))) {
    cat <- vf_ref[vf_ref[, "VFID"] == profiles[i], "VFCID"]
    data[i, "cat"] <- cat
  }
  
  # combine each profile's counts
  profiles_present <- unique(data[, "cat"])
  combined_data <- matrix(nrow = length(profiles_present), ncol = ncol(data))
  colnames(combined_data) <- colnames(data)
  rownames(combined_data) <- profiles_present
  for (i in seq_len(profiles_present)) {
    profile_subset <- data[, data[, "cat"] == profiles_present[i]]
    profile_subset <- profile_subset[, -"cat"]
    profile_sums <- colSums(profile_subset)
    combined_data[profiles_present[i], ] <- profile_sums
  }
  
  return(combined_data)
} 
