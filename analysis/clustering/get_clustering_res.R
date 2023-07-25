###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   get_clustering_res.R
###############################################################################
library(stats)


get_clustering_res <- function(boot_data, perm_data, star_bounds, num_iter) {
  results <- list()
  
  # observed stats are median values from bootstrap data
  observed_stats <- apply(boot_data, 2, median)
  abline_size = 1.5
  abline_cols <- c("green", "orange", "red", "brown", "black")
  
  for (i in seq_len(length(observed_stats))) {
    observation <- observed_stats[i]
    cat(paste0(pair_labels[i], " observation: ", observation, "\n"))
    hist(perm_data[, i], xlim = c(0, 1), breaks = 40)
    abline(v = observation, col = abline_cols[1], lwd = abline_size)
    
    pair_results <- list()
    pair_results[[1]] <- observation
    
    # bounds
    sorted_test_dist <- sort(perm_data[, i])
    bounds <- matrix(nrow = 2, ncol = length(star_bounds))
    for (j in seq_len(length(star_bounds))) {
      bounds[1, j] <- sorted_test_dist[star_bounds[[j]][[1]] * num_iter]
      bounds[2, j] <- sorted_test_dist[star_bounds[[j]][[2]] * num_iter]
      if (observation <= bounds[1, j] || observation >= bounds[2, j]) {
        pass <- TRUE
      } else {
        pass <- FALSE
      }
      cat(paste0(strrep("*", j), ": ", bounds[1, j], ", ", bounds[2, j]),
          ", passed = ", pass, "\n")
      abline(v = bounds[1, j], col = abline_cols[j + 1], lwd = abline_size)
      abline(v = bounds[2, j], col = abline_cols[j + 1], lwd = abline_size)
      
      pair_results[[2]] <- bounds
    }
    results[[i]] <- pair_results
  }
  
  return(results)
}
