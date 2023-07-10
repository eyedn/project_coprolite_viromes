###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   normalize_data.R
###############################################################################


# convert data to normalized CPM; remove outliers
normalize <- function(df) {
  # convert data frame to matrix
  df <- as.matrix(df)
  # check which rows and columns have all-zero values
  zero_rows <- which(rowSums(df) == 0)
  zero_cols <- which(colSums(df) == 0)
  # re-asign zero_* vectors to 0 if there are no rows or cols to remove
  if (is.na(zero_rows[1])) {
    zero_rows <- nrow(df) * 2
    }
  if (is.na(zero_cols[1])) {
    zero_cols <- ncol(df) * 2
    }
  # remove rows and columns with all-zero values
  df <- df[-zero_rows[[1]], -zero_cols[[1]]]

  # compute normalization + log transformation
  for (i in seq_len(ncol(df))) {
    df[, i] <- log((10^6) * df[, i] / sum(df[, i]) + 1)
  }

  return(df)
}
