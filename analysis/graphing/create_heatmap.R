###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   create_heatmap.R
###############################################################################
library(gplots)


# generate a heatmap based on differential expression
create_heatmap <- function(data, wilcox_res, max_items, cats) {
  sig_data <- data[, rownames(wilcox_res)[1:max_items]]

  ind <- c("ind_DNK", "ind_ESP", "ind_USA")
  pre <- c("pre_FJI", "pre_MDG", "pre_MEX", "pre_PER", "pre_TZA")
  pal <- c("pal_AWC", "pal_BEL", "pal_BMS", "pal_ENG", "pal_ZAF", "pal_ZAP")
  
  # determine which categoies to use
  cat <- c()
  if ("ind" %in% cats) { cat <- c(cat, ind) }
  if ("pre" %in% cats) { cat <- c(cat, pre) }
  if ("pal" %in% cats) { cat <- c(cat, pal) }
  
  sig_data_concat <- matrix(ncol = ncol(sig_data), nrow = length(cat))
  colnames(sig_data_concat) <- colnames(sig_data)
  rownames(sig_data_concat) <- cat
  
  # combine all data from same category by taking median
  for (i in seq_len(length(cat))) {
    cat_subset <- sig_data[grep(cat[i], rownames(sig_data)), ]
    
    if (is.matrix(cat_subset)) {
      cat_stats <- apply(cat_subset, 2, median)
    } else {
      cat_stats <- as.vector(cat_subset)
    }
    
    sig_data_concat[cat[i], ] <- cat_stats
  }
  
  heatmap.2(sig_data_concat, trace = "none", density.info = "none")
}

