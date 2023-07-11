###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   permute_kmeans.R
###############################################################################
library(stats)


# run kmeans many times on subsets of the data to find concensus clustering
kmeans_permute <- function(data_unscaled, data_scaled, k, num_iter,
                             graph_every) {
  clustering_probs <- matrix(nrow = num_iter, ncol = 6)
  mds_info <- list()
  
  # perform kmeans for each permutation
  for (i in seq_len(num_iter)) {
    # shuffle rows (row of data now pairs with different row name)
    permute_idx <- sample(nrow(data_scaled), nrow(data_scaled), 
                          replace = FALSE)
    data_scaled_permute <- data_scaled[permute_idx, ]
    rownames(data_scaled_permute) <- rownames(data_scaled)
    
    # run kmeans
    kmeans_result <- kmeans(data_scaled_permute, centers = k)
    cluster_assignments <- kmeans_result$cluster

    # calculate category, pair-wise clustering probabilities
    clustering_probs[i, ] <- get_pair_wise_clustering_probs(
      cluster_assignments, data_scaled_permute, k)

    # save info to create graph every for every <graph_every> iterations
    if (i %% graph_every == 0 || i == 1) {
      # create info for this iteration's mds
      data_for_graph_permute <- t(data_unscaled)[permute_idx, ]
      rownames(data_for_graph_permute) <- rownames(t(data_unscaled))
      colors <- get_colors(t(data_for_graph_permute))
      mds <- as.data.frame(cmdscale(dist(data_for_graph_permute)))
      meta_cluster_data <- cbind(cluster_assignments, colors[[1]],
                                 colors[[2]], data_scaled_permute)
      curr_iter_info <- list(meta_cluster_data, mds, k, i)
      
      # append info to mds_info for graphing later
      mds_info[[length(mds_info) + 1]] <- curr_iter_info
    }

    print(paste0(Sys.time(), " | iterations complete:", i))
  }

  return(list(clustering_probs, mds_info))
}
