###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   aux_heatmap_fxns.R
###############################################################################


# function to add a row order column
add_row_order <- function(df) {
  df$order <- seq_len(nrow(df))
  return(df)
}

# function to merge data frames and retain row order of the first data frame
merge_and_retain_order <- function(x, y, by.x, by.y) {
  x <- add_row_order(x)
  merged_df <- merge(x, y, by.x = by.x, by.y = by.y)
  merged_df <- merged_df[order(merged_df$order), ]
  merged_df$order <- NULL  # Remove the order column
  return(merged_df)
}
