###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   get_prop.R
###############################################################################


# return df contain information on enzyme class counts of samples
get_prop <- function(data, cat, var) {
  class_counts <- matrix(nrow = length(var), ncol = length(cat))
  rownames(class_counts) <- var
  colnames(class_counts) <- cat
  
  data <- as.matrix(data)
  for (i in seq_len(ncol(data))) {
    data[, i] <- 10^6 * data[, i] / sum(data[, i])
  }
  
  for (i in seq_len(nrow(class_counts))) {
    class_subset <- data[startsWith(rownames(data), var[i]), , drop=FALSE]
    
    for (j in seq_len(ncol(class_counts))) {
      group <- cat[j]
      group_subset <- class_subset[, grep(group, colnames(class_subset)), 
                                   drop=FALSE]
      group_sums <- c()
      for (k in seq_len(ncol(group_subset))) {
        group_sums <- c(group_sums, sum(group_subset[, k], na.rm = TRUE))
      }
      class_counts[i, j] <- median(group_sums, na.rm = TRUE)
    }
  }
  
  return(class_counts)
}
