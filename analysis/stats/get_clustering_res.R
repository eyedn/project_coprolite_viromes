###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   get_clustering_res.R
###############################################################################
library(stats)

get_clustering_res <- function(boot_data, perm_data, star_bounds, num_iter, k) {
  results <- list()
  # observed stats are median values from bootstrap data
  observed_stats <- apply(boot_data, 2, median)
  abline_size <- 1.5
  abline_cols <- c("green", "orange", "red", "brown", "black")
  
  # NEW: output directory + ensure it exists
  out_dir <- "/Users/aydinkaratas/Documents/ucla/research/project_coprolite_viromes_NOT_CODE/figures/metabolism"
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  
  for (i in seq_len(length(observed_stats))) {
    observation <- observed_stats[i]
    cat(paste0(pair_labels[i], " observation: ", observation, "\n"))
    # NEW: open svg device per figure
    svg_file <- file.path(out_dir, paste0("hist_", gsub("[^A-Za-z0-9_-]+", "_", pair_labels[i]), k,".svg"))
    svglite::svglite(svg_file)
    
    hist(perm_data[, i], xlim = c(0, 1), breaks = 40, main = pair_labels[i])
    abline(v = observation, col = abline_cols[1], lwd = abline_size)
    
    pair_results <- list()
    pair_results[[1]] <- observation
    
    # bounds
    sorted_test_dist <- sort(perm_data[, i])
    bounds <- matrix(nrow = 2, ncol = length(star_bounds))
    for (j in seq_len(length(star_bounds))) {
      bounds[1, j] <- sorted_test_dist[star_bounds[[j]][[1]] * num_iter]
      bounds[2, j] <- sorted_test_dist[star_bounds[[j]][[2]] * num_iter]
      if (observation < bounds[1, j] || observation > bounds[2, j]) {
        pass <- TRUE
      } else {
        pass <- FALSE
      }
      cat(paste0("\t", strrep("*", j), ": ", bounds[1, j], ", ", bounds[2, j]),
          ", passed = ", pass, "\n")
      abline(v = bounds[1, j], col = abline_cols[j + 1], lwd = abline_size)
      abline(v = bounds[2, j], col = abline_cols[j + 1], lwd = abline_size)
      
      pair_results[[2]] <- bounds
    }
    results[[i]] <- pair_results
    
    # NEW: close device after each figure
    dev.off()
  }
  
  return(results)
}