###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   permute_kmeans.R
###############################################################################
library(stats)
library(progress)


# run kmeans many times on subsets of the data to find concensus clustering
kmeans_permute <- function(data_t_matrix, k, num_iter) {
  
  permute_stats <- matrix(nrow = num_iter, ncol = 6)
  
  # initialize progress bar
  pb <- progress_bar$new(format = "Time: :elapsedfull [:bar] Iteration :current/:total (:percent)", total = num_iter)
  
  # perform kmeans for each permutation
  for (i in seq_len(num_iter)) {
    # shuffle rows (row of data now pairs with different row name)
    permute_idx <- sample(nrow(data_t_matrix), nrow(data_t_matrix), 
                          replace = FALSE)
    data_t_matrix_permute <- data_t_matrix[permute_idx, ]
    rownames(data_t_matrix_permute) <- rownames(data_t_matrix)
    
    # run kmeans
    kmeans_result <- kmeans(data_t_matrix_permute, centers = k)
    cluster_assignments <- kmeans_result$cluster

    # calculate category, pair-wise clustering probabilities
    permute_stats[i, ] <- get_pair_wise_clustering_probs(cluster_assignments,
                                                       data_t_matrix_permute, k)
  
    # update progress bar
    pb$tick()
  }

  return(permute_stats)
}
