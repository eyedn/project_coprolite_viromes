###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   get_median_lifestyles.R
###############################################################################


# gets median value of temperate-to-virulent ratio
get_median_lifestyles <- function(data, num_iter) {
  
  # initialize progress bar
  pb <- progress_bar$new(format = "Time: :elapsedfull [:bar] Iteration :current/:total (:percent)", total = num_iter)
  
  boot_stats <- matrix(nrow = num_iter, ncol = 3)
  colnames(boot_stats) <- c("ind", "pre", "pal")
  
  data["temp_ness", ] <- data["temperate", ] /
                                  data["virulent", ]
  data <- as.matrix(data)
  
  # subset data by category for re-sampling later
  ind_subset <- data[, grep("ind", colnames(data))]
  pal_subset <- data[, grep("pal", colnames(data))]
  pre_subset <- data[, grep("pre", colnames(data))]

  # perform kmeans for each bootstrap iteration
  for (i in seq_len(num_iter)) {
    # create re-sampled data
    ind_resample <- ind_subset[, sample(ncol(ind_subset), ncol(ind_subset),
                                        replace = TRUE)]
    pal_resample <- pal_subset[, sample(ncol(pal_subset), ncol(pal_subset),
                                        replace = TRUE)]
    pre_resample <- pre_subset[, sample(ncol(pre_subset), ncol(pre_subset),
                                        replace = TRUE)]

    boot_stats[i, "ind"] <- median(ind_resample["temp_ness", ])
    boot_stats[i, "pre"] <- median(pre_resample["temp_ness", ])
    boot_stats[i, "pal"] <- median(pal_resample["temp_ness", ])

    # update progress bar
    pb$tick()
  }

  return(boot_stats)
}
