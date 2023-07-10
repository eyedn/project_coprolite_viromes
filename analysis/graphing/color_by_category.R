###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   color_by_category.R
###############################################################################


# create a vector to color mds by time catagory and orgin
generate_colors <- function(df) {
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
