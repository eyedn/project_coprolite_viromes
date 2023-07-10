###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   clustering_functions
###############################################################################
source("graph_functions.R")
library(factoextra)
library(cluster)
library(pdfCluster)
library(MASS)


# create a vector of cluster occurrences or a subset
count_clusters <- function(subset_clusters, k) {
  counts <- rep(0, k)
  for (i in seq_len(length(subset_clusters))) {
    cluster <- subset_clusters[i]
    counts[cluster] <- counts[cluster] + 1
  }
  return(counts)
}

# calc probability that 2 samples (same category) in the same cluster (2)
prob_same_cat <- function(cat, k) {
  # calc the total number of pairs possible within this category
  tot_pairs <- sum(cat) * (sum(cat) - 1) * 0.5
  # iterate through all clusters to get prob of pair in same cluster
  clus_pairs <- 0
  for (i in seq_len(k)) {
    clus_pairs <- clus_pairs + cat[i] * (cat[i] - 1) * 0.5
  }
  return(clus_pairs / tot_pairs)
}

# calc probability that 2 samples (different categories) in same cluster (k)
prob_diff_cat <- function(cat1, cat2, k) {
  # calc the total number of pairs possible between category 1 & 2
  tot_pairs <- sum(cat1) * sum(cat2)
  # iterate through all clusters to get prob of pair in same cluster
  clus_pairs <- 0
  for (i in seq_len(k)) {
    clus_pairs <- clus_pairs + cat1[i] * cat2[i]
  }
  return(clus_pairs / tot_pairs)
}