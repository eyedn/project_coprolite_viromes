###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   get_cat_medians.R
###############################################################################


# create a beeswarms plot of paired-cluserting tendencies
get_cat_medians <- function(data) {
  class_data <- matrix(nrow = length(cat_labels), ncol = ncol(data))
  rownames(class_data) <- cat_labels
  colnames(class_data) <- colnames(data)
  
  for (i in seq_len(length(cat_labels))) {
    cat_subset <- data[startsWith(rownames(data), cat_labels[i]), ,
                       drop = FALSE]
    for (j in seq_len(ncol(data))) {
      class_data[cat_labels[i], j] <- median(cat_subset[, j])
    }
  }
  
  return(class_data)
}
