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

# run kmeans many times on subsets of the data to find concensus clustering
consensus_clustering <- function(all_data, k, num_iter, sample_fraction,
                                 seed, categories, graph_every, plot_dir) {
  # parse data into two categories: one for visualizing, one for kmeans
  data_for_graph <- t(all_data[[1]])
  data <- all_data[[2]]
  consensus_mat <- matrix(0, nrow = nrow(data), ncol = nrow(data))
  ari_values <- vector(length = num_iter)
  probs <- matrix(nrow = num_iter, ncol = 6)
  # create subsets for each sample category
  ind_subset <- data[grep("ind", rownames(data)), ]
  pal_subset <- data[grep("pal", rownames(data)), ]
  pre_subset <- data[grep("pre", rownames(data)), ]
  # generate random subset sample indexes for ind
  all_sample_ind <- replicate(num_iter,
                              sample(seq_len(nrow(ind_subset)),
                                     size = round(sample_fraction *
                                                    nrow(ind_subset))))
  # generate random subset sample indexes for pal
  all_sample_pal <- replicate(num_iter,
                              sample(seq_len(nrow(pal_subset)),
                                     size = round(sample_fraction *
                                                    nrow(pal_subset))))
  all_sample_pal <- all_sample_pal + nrow(ind_subset)
  # generate random subset sample indexes for pre
  all_sample_pre <- replicate(num_iter,
                              sample(seq_len(nrow(pre_subset)),
                                     size = round(sample_fraction *
                                                    nrow(pre_subset))))
  all_sample_pre <- all_sample_pre + nrow(ind_subset) + nrow(pal_subset)
  for (i in 1:num_iter) {
    # randomly sample a fraction of the data
    sample_ind <- all_sample_ind[, i]
    sample_pal <- all_sample_pal[, i]
    sample_pre <- all_sample_pre[, i]
    # combine all indeces togather to make a sample subset
    sample_indices <- c(sample_ind, sample_pre, sample_pal)
    # extract these sample indeces for both the graphing and kmeans data
    sample_data_for_graph <- data_for_graph[sample_indices, ]
    sample_data <- data[sample_indices, ]
    # Perform k-means clustering on the sampled data
    kmeans_result <- kmeans(sample_data, centers = k)
    cluster_assignment <- kmeans_result$cluster
    # calc sample-sample probs
    probs[i, ] <- subset_clustering_behaviour(cluster_assignment,
                                              sample_data, k)
    # update consensus matrix
    for (j in seq_along(sample_indices)) {
      for (l in seq_along(sample_indices)) {
        consensus_mat[sample_indices[j], sample_indices[l]] <-
          consensus_mat[sample_indices[j], sample_indices[l]] +
          (cluster_assignment[j] == cluster_assignment[l])
      }
    }
    # calculate Adjusted Rand Index (ARI)
    known_groups <- categories[[1]][sample_indices]
    ari_values[i] <- adj.rand.index(cluster_assignment, known_groups)
    # display graph every <graph_every> iterations
    if (i %% graph_every == 0 || i == 1) {
      mds <- as.data.frame(cmdscale(dist(sample_data_for_graph)))
      meta_clus_data <- cbind(cluster_assignment, categories[[1]][sample_indices],
                        categories[[2]][sample_indices], sample_data)
      mds_plot(meta_clus_data, mds, k, i, seed, plot_dir)
    }
    print(paste0(Sys.time(), " | iterations complete:", i))
  }
  av_probs <- colMeans(probs, na.rm = TRUE)
  sd_probs <- apply(probs, 2, sd)
  consensus_mat <- consensus_mat / num_iter  # Normalize the consensus matrix
  return(list(consensus_mat, ari_values, probs, av_probs, sd_probs))
}
