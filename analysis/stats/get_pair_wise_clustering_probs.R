###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   get_pair_wise_clustering_probs.R
###############################################################################


get_pair_wise_clustering_probs <- function(cluster_assignments, data, k) {
  # get cluster counts for all categories
  ind_clusters <- get_cluster_counts(
    cluster_assignments[grep("ind", rownames(data))], k
  )
  pre_clusters <- get_cluster_counts(
    cluster_assignments[grep("pre", rownames(data))], k
  )
  pal_clusters <- get_cluster_counts(
    cluster_assignments[grep("pal", rownames(data))], k
  )

  # probabilities for same category in same cluster
  p_ind_ind <- get_clustering_prob(k, ind_clusters)
  p_pre_pre <- get_clustering_prob(k, pre_clusters)
  p_pal_pal <- get_clustering_prob(k, pal_clusters)
  
  # probabilities for different category in same cluster
  p_ind_pal <- get_clustering_prob(k, ind_clusters, pal_clusters)
  p_ind_pre <- get_clustering_prob(k, ind_clusters, pre_clusters)
  p_pre_pal <- get_clustering_prob(k, pre_clusters, pal_clusters)

  return(c(p_ind_ind, p_pre_pre, p_pal_pal, p_ind_pal, p_ind_pre, p_pre_pal))
}
