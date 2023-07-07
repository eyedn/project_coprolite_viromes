###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   clustering_functions
###############################################################################
source("graph_functions.R")
library(factoextra)
library(cluster)
library(pdfCluster)

# iterate through many kmeans and find average probabilities
kmeans_iter <- function(data, categories, k, init_seed, num_iter, pca, type,
                        graph_every, plot_dir) {
  ari_values <- vector(length = num_iter)
  probs <- matrix(nrow = num_iter, ncol = 6)
  for (i in seq_len(num_iter)) {
    iter_probs <- kmeans_fx(data, categories, k, init_seed + i - 1)
    # calc sample-sample probs
    ari_values[i] <- adj.rand.index(iter_probs[[1]][,1], iter_probs[[1]][,2])
    probs[i, ] <- iter_probs[[2]]
    # every <graph_every> number of iterations, generate a pca graph
    if (i %% graph_every == 0 || i == 1) {
      pca_plot(iter_probs[[1]], pca, 1, 2, k, type, i, plot_dir)
    }
    print(paste0(Sys.time(), " | iterations complete:", i))
  }
  av_probs <- colMeans(probs, na.rm = TRUE)
  sd_probs <- apply(probs, 2, sd)
  return(list(probs, av_probs, sd_probs, ari_values))
}

# do an iteration of kmeans given a seed
kmeans_fx <- function(data, categories, k, seed) {
  set.seed(seed)
  # perform kmeans clustering and identify clusters
  kmeans_results <- kmeans(data, centers = k)
  clusters <- kmeans_results$cluster
  # combine clusters data with categories vector
  clus_cat_data <- cbind(clusters, categories[[1]])
  # subset data by category and determine the distribution among the clusters
  ind_clusters_data <- subset_data_stats(clus_cat_data, 1, 2, "ind", k)
  pre_clusters_data <- subset_data_stats(clus_cat_data, 1, 2, "pre", k)
  pal_clusters_data <- subset_data_stats(clus_cat_data, 1, 2, "pal", k)
  # calculate the following probabilities
  # probability 2 randomly chosen ind are in the same cluster
  p_ind <- prob_same_cat(ind_clusters_data, k)
  # probability 2 randomly chosen pre ||
  p_pre <- prob_same_cat(pre_clusters_data, k)
  # probability 2 randomly chosen pal ||
  p_pal <- prob_same_cat(pal_clusters_data, k)
  # probability 1 randomly chosen ind and 1 randomly chosen pal ||
  p_ind_pal <- prob_diff_cat(ind_clusters_data, pal_clusters_data, k)
  # probability 1 randomly chosen ind and 1 randomly chosen pre ||
  p_ind_pre <- prob_diff_cat(ind_clusters_data, pre_clusters_data, k)
  # probability 1 randomly chosen pre and 1 randomly chosen pal ||
  p_pre_pal <- prob_diff_cat(pre_clusters_data, pal_clusters_data, k)
  # return probabilities
  all_probs <- c(p_ind, p_pre, p_pal, p_ind_pal, p_ind_pre, p_pre_pal)
  clus_data <- cbind(clus_cat_data, categories[[2]], data)
  return(list(clus_data, all_probs))
}

# subset data by category
subset_data_stats <- function(data, obs_col, subset_col, category, k) {
  subset <- data[data[, subset_col] == category, ]
  cluster_vec <- factor(subset[, obs_col], level = c(1:k))
  cluster_data <- table(cluster_vec)
  output <- unname(cluster_data)
  return(output)
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
  tot_pairs <- sum(sum(cat1) * sum(cat2))
  # iterate through all clusters to get prob of pair in same cluster
  clus_pairs <- 0
  for (i in seq_len(k)) {
    clus_pairs <- clus_pairs + cat1[i] * cat2[i]
  }
  return(clus_pairs / tot_pairs)
}

# run kmeans many times on subsets of the data to find concensus clustering
consensus_clustering <- function(all_data, k, num_iter, sample_fraction, 
                                 init_seed, categories, graph_every,
                                 type, plot_dir) {
  # parse data into two categories: one for visualizing, one for kmeans
  data_for_graph = t(all_data[[1]])
  data = all_data[[2]]
  consensus_mat <- matrix(0, nrow = nrow(data), ncol = nrow(data))
  ari_values <- vector(length = num_iter)
  probs <- matrix(nrow = num_iter, ncol = 6)
  # create subsets for each sample category
  ind_subset <- data[grep("ind", rownames(data)), ]
  pal_subset <- data[grep("pal", rownames(data)), ]
  pre_subset <- data[grep("pre", rownames(data)), ]
  for (i in 1:num_iter) {
    # iterate a set seed for reproducibility
    set.seed(init_seed + i - 1)
    # randomly sample a fraction of the data
    sample_ind <- sample(1:nrow(ind_subset), size = round(sample_fraction * 
                                                            nrow(ind_subset)))
    sample_pal <- sample(1:nrow(pal_subset), size = round(sample_fraction * 
                                                            nrow(pal_subset)))
    sample_pal <- sample_pal + nrow(ind_subset)
    sample_pre <- sample(1:nrow(pre_subset), size = round(sample_fraction * 
                                                            nrow(pre_subset))) 
    sample_pre <- sample_pre + nrow(ind_subset) + nrow(pal_subset)
    sample_indices <- c(sample_ind, sample_pre, sample_pal)
    sample_data_for_graph <- data_for_graph[sample_indices, ]
    sample_data <- data[sample_indices, ]
    # Perform k-means clustering on the sampled data
    kmeans_result <- kmeans(sample_data, centers = k)
    cluster_assignment <- kmeans_result$cluster
    # calc sample-sample probs
    probs[i, ] <- subset_clustering_behaviour(cluster_assignment, 
                                              sample_data, k)
    # Update consensus matrix
    for (j in 1:length(sample_indices)) {
      for (l in 1:length(sample_indices)) {
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
      # pca <- prcomp(sample_data)
      mds_data <- cbind(cluster_assignment, categories[[1]][sample_indices],
                        categories[[2]][sample_indices], sample_data)
      # pca_plot(pca_data, pca, 1, 2, k, type, i, plot_dir)
      pca_plot(pca_data, mds, 1, 2, k, type, i, plot_dir)
    }
    print(paste0(Sys.time(), " | iterations complete:", i))
  }
  av_probs <- colMeans(probs, na.rm = TRUE)
  sd_probs <- apply(probs, 2, sd)
  consensus_mat <- consensus_mat / num_iter  # Normalize the consensus matrix
  return(list(consensus_mat, ari_values, probs, av_probs, sd_probs))
}

# clustering probs
subset_clustering_behaviour <- function (cluster_assignments, sample_data, k) {
  # subset data by category and determine the distribution among the clusters
  ind_clusters_data <- unname(table(cluster_assignments[grep("ind", 
                                                             rownames(sample_data))]))
  pre_clusters_data <- unname(table(cluster_assignments[grep("pre", 
                                                             rownames(sample_data))]))
  pal_clusters_data <- unname(table(cluster_assignments[grep("pal", 
                                                             rownames(sample_data))]))
  # calculate the following probabilities
  # probability 2 randomly chosen ind are in the same cluster
  p_ind <- prob_same_cat(ind_clusters_data, k)
  # probability 2 randomly chosen pre ||
  p_pre <- prob_same_cat(pre_clusters_data, k)
  # probability 2 randomly chosen pal ||
  p_pal <- prob_same_cat(pal_clusters_data, k)
  # probability 1 randomly chosen ind and 1 randomly chosen pal ||
  p_ind_pal <- prob_diff_cat(ind_clusters_data, pal_clusters_data, k)
  # probability 1 randomly chosen ind and 1 randomly chosen pre ||
  p_ind_pre <- prob_diff_cat(ind_clusters_data, pre_clusters_data, k)
  # probability 1 randomly chosen pre and 1 randomly chosen pal ||
  p_pre_pal <- prob_diff_cat(pre_clusters_data, pal_clusters_data, k)
  # return probabilities
  return(c(p_ind, p_pre, p_pal, p_ind_pal, p_ind_pre, p_pre_pal))
}