###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   get_median_lifestyles.R
###############################################################################


# gets median value of temperate-to-virulent ratio
get_median_ratios <- function(data, num_iter, numer, denom) {
  
  # initialize progress bar
  pb <- progress_bar$new(format = "Time: :elapsedfull [:bar] Iteration :current/:total (:percent)", total = num_iter)
  
  boot_stats <- matrix(nrow = num_iter, ncol = 3)
  colnames(boot_stats) <- c("ind", "pre", "pal")
  
  
  data["ratio", ] <- data[numer, ] / data[denom, ]
  data["cat", ] <- substr(colnames(data), 1, 3)
  data <- as.data.frame(t(data))
  data[, "ratio"] <- as.numeric(data[, "ratio"])
  
  # subset data by category for re-sampling later
  ind_subset <- data[data[, "cat"] == "ind", ]
  pal_subset <- data[data[, "cat"] == "pal", ]
  pre_subset <- data[data[, "cat"] == "pre", ]

  # perform kmeans for each bootstrap iteration
  for (i in seq_len(num_iter)) {
    # create re-sampled data
    ind_resample <- ind_subset[sample(nrow(ind_subset), nrow(ind_subset),
                                      replace = TRUE), ]
    pal_resample <- pal_subset[sample(nrow(pal_subset), nrow(pal_subset),
                                      replace = TRUE), ]
    pre_resample <- pre_subset[sample(nrow(pre_subset), nrow(pre_subset),
                                      replace = TRUE), ]
    
    boot_stats[i, "ind"] <- median(ind_resample[, "ratio"])
    boot_stats[i, "pre"] <- median(pre_resample[, "ratio"])
    boot_stats[i, "pal"] <- median(pal_resample[, "ratio"])
    
    # update progress bar
    pb$tick()
  }

  return(boot_stats)
}
