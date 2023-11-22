###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   get_ec_class_counts.R
###############################################################################


# return df containing raw counts ec's, collapsed by ec class
get_ec_class_counts <- function(data, classes) {
  class_counts <- matrix(nrow = length(classes), ncol = ncol(data))
  rownames(class_counts) <- classes
  colnames(class_counts) <- colnames(data)
  
  for (i in seq_len(length(classes))) {
    class_subset <- data[startsWith(rownames(data), classes[i]), , drop=FALSE]
    col_sums <- vector(length = ncol(data))
    for (j in seq_len(ncol(data))) {
      col_sums[j] <- sum(class_subset[, j])
    }
    class_counts[i, ] <- col_sums
  }
  
  return(class_counts)
}
