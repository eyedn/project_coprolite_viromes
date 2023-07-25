###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   kmeans_bootstrap.R
###############################################################################
library(stats)


# run kmeans many times on subsets of the data to find concensus clustering
kmeans_bootstrap <- function(data_t_matrix, k, num_iter) {
  boot_stats <- matrix(nrow = num_iter, ncol = 6)

  # subset data by category for re-sampling later
  ind_subset <- data_t_matrix[grep("ind", rownames(data_t_matrix)), ]
  pal_subset <- data_t_matrix[grep("pal", rownames(data_t_matrix)), ]
  pre_subset <- data_t_matrix[grep("pre", rownames(data_t_matrix)), ]

  # perform kmeans for each bootstrap iteration
  for (i in seq_len(num_iter)) {
    # create re-sampled data
    ind_resample <- ind_subset[sample(nrow(ind_subset), nrow(ind_subset),
                                      replace = TRUE), ]
    pal_resample <- pal_subset[sample(nrow(pal_subset), nrow(pal_subset),
                                      replace = TRUE), ]
    pre_resample <- pre_subset[sample(nrow(pre_subset), nrow(pre_subset),
                                      replace = TRUE), ]
    data_t_matrix_resample <- rbind(ind_resample, pal_resample, pre_resample)

    # run kmeans
    kmeans_result <- kmeans(data_t_matrix_resample, centers = k)
    cluster_assignments <- kmeans_result$cluster

    # calculate category, pair-wise clustering probabilities
    boot_stats[i, ] <- get_pair_wise_clustering_probs(
      cluster_assignments, data_t_matrix_resample, k)

    print(paste0(Sys.time(), " | iterations complete:", i))
  }

  return(boot_stats)
}
