###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   normalize_data.R
###############################################################################


normalize_data <- function(df) {
  df <- as.matrix(df)
  
  # identify rows and columns with all zeros
  zero_rows <- unname(which(rowSums(df) == 0))
  zero_cols <- unname(which(colSums(df) == 0))
  
  # identify rows with all NAs
  na_rows <- unname(which(is.na(rowSums(df))))
  
  # combine zero_rows and na_rows
  remove_rows <- unique(c(zero_rows, na_rows))
  
  # remove rows and columns with all zeros or NAs
  if (length(remove_rows) > 0) {
    df <- df[-remove_rows, ]
  }
  if (length(zero_cols) > 0) {
    df <- df[, -zero_cols]
  }
  
  # normalize by log(CPM + 1)
  for (i in seq_len(ncol(df))) {
    df[, i] <- log10(10^6 * df[, i] / sum(df[, i], na.rm = TRUE) + 1)
  }
  
  return(df)
}
