###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   kmeans_bootstrap.R
###############################################################################
library(stats)


# run kmeans many times on subsets of the data to find concensus clustering
kmeans_bootstrap <- function(data, data_t_matrix, k, num_iter,
                             graph_every) {
  clustering_probs <- matrix(nrow = num_iter, ncol = 6)
  mds_info <- list()

  # perform boot strapping by re-sampling for each category
  ind_subset <- data_t_matrix[grep("ind", rownames(data_t_matrix)), ]
  pal_subset <- data_t_matrix[grep("pal", rownames(data_t_matrix)), ]
  pre_subset <- data_t_matrix[grep("pre", rownames(data_t_matrix)), ]

  # perform kmeans for <num_iter> iterations of bootstrapping
  for (i in seq_len(num_iter)) {
    # get indexes for re-sampling
    ind_resample_idx <- sample(nrow(ind_subset), nrow(ind_subset),
                               replace = TRUE)
    pal_resample_idx <- sample(nrow(pal_subset), nrow(pal_subset),
                               replace = TRUE)
    pre_resample_idx <- sample(nrow(pre_subset), nrow(pre_subset),
                               replace = TRUE)

    # create re-sampled subsets
    ind_resample <- ind_subset[ind_resample_idx, ]
    pal_resample <- pal_subset[pal_resample_idx, ]
    pre_resample <- pre_subset[pre_resample_idx, ]

    # combine subsets into combines re-sample
    data_t_matrix_resample <- rbind(ind_resample, pal_resample, pre_resample)

    # run kmeans
    kmeans_result <- kmeans(data_t_matrix_resample, centers = k)
    cluster_assignments <- kmeans_result$cluster

    # calculate category, pair-wise clustering probabilities
    clustering_probs[i, ] <- get_pair_wise_clustering_probs(
      cluster_assignments, data_t_matrix_resample, k)

    # save info to create graph every for every <graph_every> iterations
    if (i %% graph_every == 0 || i == 1) {
      # subset unscaled data
      ind_unscaled <- t(data)[grep("ind", rownames(data_t_matrix)), ]
      pal_unscaled <- t(data)[grep("pal", rownames(data_t_matrix)), ]
      pre_unscaled <- t(data)[grep("pre", rownames(data_t_matrix)), ]
      
      # re-sampled unscaled subsets
      ind_unscaled <- ind_unscaled[ind_resample_idx, ]
      pal_unscaled <- pal_unscaled[pal_resample_idx, ]
      pre_unscaled <- pre_unscaled[pre_resample_idx, ]
      
      # create info for this iteration's mds
      data_for_graph_resample <- rbind(ind_unscaled, pal_unscaled, 
                                       pre_unscaled)
      colors <- get_colors(t(data_for_graph_resample))
      mds <- as.data.frame(cmdscale(dist(data_for_graph_resample)))
      meta_cluster_data <- cbind(cluster_assignments, colors[[1]],
                                 colors[[2]], data_t_matrix_resample)
      curr_iter_info <- list(meta_cluster_data, mds, k, i)
      
      # append info to mds_info for graphing later
      mds_info[[length(mds_info) + 1]] <- curr_iter_info
    }

    print(paste0(Sys.time(), " | iterations complete:", i))
  }

  return(list(clustering_probs, mds_info))
}
