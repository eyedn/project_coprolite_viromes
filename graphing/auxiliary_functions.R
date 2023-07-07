###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   auxillary_functions
###############################################################################
library(stats)

# create a vector to color mds by time catagory and orgin
color_by_catagory <- function(df) {
  color_origin <- c()
  color_time <- c()
  samples <- colnames(df)
  for (s in seq_len(length(samples))) {
    origin <- substr(samples[s], 1, 7)
    time <- substr(samples[s], 1, 3)
    color_origin <- c(color_origin, origin)
    color_time <- c(color_time, time)
  }
  return(list(color_time, color_origin))
}

# convert data to normalized CPM; remove outliers
clean_data <- function(df) {
  # convert dataframe to matrix
  df <- as.matrix(df)
  # check which rows and columns have all-zero values
  zero_rows <- which(rowSums(df) == 0)
  zero_cols <- which(colSums(df) == 0)
  # reasign zero_* vectors to 0 if there are no rows or cols to remove
  if (is.na(zero_rows[1])) { zero_rows <- nrow(df)*2 }
  if (is.na(zero_cols[1])) { zero_cols <- ncol(df)*2 } 
  # remove rows and columns with all-zero values
  df <- df[-zero_rows[[1]], -zero_cols[[1]]]
  
  # compute normalization + log transformation
  for (i in seq_len(ncol(df))) {
    df[, i] <- log2((10^6) * df[, i] / sum(df[, i]) + 1)
  }
  
  # remove columns with large values
  # threshold <- mean(df) + 3 * sd(df)  # threshold is within 3 standard dev's
  # df <- df[, apply(df, 2, max) < threshold]
  # return matrix (still named df)
  return(df)
}

# calc how tight a cluster is by within cluster sum squares
calculate_WCSS <- function(subset_data) {
  mds <- as.data.frame(cmdscale(dist(subset_data)))
  centroid <- colMeans(subset_data[, c(1, 2)])
  distances <- apply(subset_data[, c(1, 2)], 1, 
                     function(point) sum((point - centroid)^2))
  WCSS <- sum(distances)
  return(WCSS)
}