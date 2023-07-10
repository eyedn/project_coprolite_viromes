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