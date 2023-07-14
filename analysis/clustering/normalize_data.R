###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   normalize_data.R
###############################################################################


normalize_data <- function(df) {
  df <- as.matrix(df)
  
  zero_rows <- which(rowSums(df) == 0)
  zero_cols <- which(colSums(df) == 0)
  
  # re-assign zero_rows/cols to inconsequential numbers if there are none
  if (is.na(zero_rows[1])) {
    zero_rows <- nrow(df) * 2
    }
  if (is.na(zero_cols[1])) {
    zero_cols <- ncol(df) * 2
  }
  
  df <- df[-zero_rows[[1]], -zero_cols[[1]]]
  
  # normalize by log(CPM + 1)
  for (i in seq_len(ncol(df))) {
    df[, i] <- log((10^6) * df[, i] / sum(df[, i]) + 1)
  }
  
  return(df)
}
