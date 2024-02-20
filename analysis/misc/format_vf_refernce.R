###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   format_vf_reference.R
###############################################################################


# generate a heatmap based on differential expression
format_vf_reference <- function(vf_reference) {
  
  # format vf reference
  colnames(vf_reference) <- vf_reference[1, ]
  vf_reference <- vf_reference[-1, c("VFID", "VFCID")]
  
  # define a 3rd col that assigns each VFCID a unique number 1
  vf_reference[, "color"] <- NA
  vfcid_seen <- list()
  color_num <- 1
  for (i in seq_len(nrow(vf_reference))) {
    if (vf_reference[i, "VFCID"] %in% names(vfcid_seen)) {
      vf_reference[i, "color"] <- vfcid_seen[[vf_reference[i, "VFCID"]]]
    } else {
      vfcid_seen[[vf_reference[i, "VFCID"]]] <- color_num
      vf_reference[i, "color"] <- vfcid_seen[[vf_reference[i, "VFCID"]]]
      color_num <- color_num + 1
    }
  }
  
  return(vf_reference)
}
