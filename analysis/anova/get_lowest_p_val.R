###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   get_lowest_p_val.R
###############################################################################
library(stats)


# bootstrap p-values from diff repres. search to get most significant values
get_lowest_p_val <- function(p_vals, ci_upper, num_iter) {
  # create vector of groups for kruskal wallis test
  resample_res <- vector(length = num_iter)
  
  for (i in seq_len(num_iter)) {
    resample <- sample(p_vals[, 1], nrow(p_vals), replace = TRUE)
    sorted_resample <- sort(resample)
    resample_res[i] <- sorted_resample[ci_upper*length(sorted_resample)]
  } 
  
  sorted_res <- sort(resample_res)
  cutoff <- sorted_res[ci_upper*num_iter]
  
  p_vals <- cbind(p_vals, rownames(p_vals))
  lowest_p_val <- p_vals[p_vals[, 1] <= cutoff, ]
  
  return(resample_res)
}
