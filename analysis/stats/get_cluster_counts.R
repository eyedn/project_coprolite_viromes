###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   get_cluster_counts.R
###############################################################################


get_cluster_counts <- function(clusters_data, k) {
  counts <- rep(0, k)
  
  # record counts for each cluster
  for (i in seq_len(length(clusters_data))) {
    cluster <- clusters_data[i]
    counts[cluster] <- counts[cluster] + 1
  }
  
  return(counts)
}
