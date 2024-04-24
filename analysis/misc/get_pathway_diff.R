###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   get_pathway_diff.R
###############################################################################
library(boot)
library(progress)


# determine which pathway comparisons are significantly different
get_pathway_diff <- function(data, pathways, num_iter) {
  
  # parse out pathways
  pathways_in_data <- data[, intersect(colnames(data), pathways[[1]])]
  
  # get differential represented genes
  diff_repress <- get_diff_repres_cols(data = pathways_in_data)
  diff_repress[, 2:4] <- ifelse(diff_repress[, 2:4] > 0.05, NA,
                                             diff_repress[, 2:4])
  
  # get bootstrapped medians
  boot_median <- function(data, indices) {
    return(median(data[indices]))
  }
  categories <- c("ind", "pre", "pal")
  median_cols <- matrix(NA, nrow = nrow(diff_repress), ncol = 3)
  colnames(median_cols) <- categories
  diff_repress <- cbind(diff_repress, median_cols)
  
  # initialize progress bar
  pb <- progress_bar$new(format = "Time: :elapsedfull [:bar] Iteration :current/:total (:percent)", 
                         total = length(categories) * nrow(diff_repress))
  
  for (cat in categories) {
    for (gene in rownames(diff_repress)) {
      cat_data <- data[grepl(cat, rownames(data)), gene,drop = FALSE]
      diff_repress[gene, cat] <- mean(cat_data)
      
      pb$tick()
    }
  }
  return(diff_repress)
}
