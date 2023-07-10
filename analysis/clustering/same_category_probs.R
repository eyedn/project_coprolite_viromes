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
