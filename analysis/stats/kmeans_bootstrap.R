###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   kmeans_bootstrap.R
###############################################################################
library(stats)
library(progress)


# run kmeans many times on subsets of the data to find concensus clustering
kmeans_bootstrap <- function(data, k, num_iter) {
  boot_stats <- matrix(nrow = num_iter, ncol = 6)

  # initialize progress bar
  pb <- progress_bar$new(format = "Time: :elapsedfull [:bar] Iteration :current/:total (:percent)", total = num_iter)
  
  # subset data by category for re-sampling later
  ind_subset <- data[grep("ind", rownames(data)), ]
  pal_subset <- data[grep("pal", rownames(data)), ]
  pre_subset <- data[grep("pre", rownames(data)), ]

  # perform kmeans for each bootstrap iteration
  for (i in seq_len(num_iter)) {
    # create re-sampled data
    ind_resample <- ind_subset[sample(nrow(ind_subset), nrow(ind_subset),
                                      replace = TRUE), ]
    pal_resample <- pal_subset[sample(nrow(pal_subset), nrow(pal_subset),
                                      replace = TRUE), ]
    pre_resample <- pre_subset[sample(nrow(pre_subset), nrow(pre_subset),
                                      replace = TRUE), ]
    data_resample <- rbind(ind_resample, pal_resample, pre_resample)

    # run kmeans
    kmeans_result <- kmeans(data_resample, centers = k)
    cluster_assignments <- kmeans_result$cluster

    # calculate category, pair-wise clustering probabilities
    boot_stats[i, ] <- get_pair_wise_clustering_probs(
      cluster_assignments, data_resample, k)

    # update progress bar
    pb$tick()
  }

  return(boot_stats)
}
