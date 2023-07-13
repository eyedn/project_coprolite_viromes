###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   get_diff_express.R
###############################################################################
library(stats)


# applies a wilcoxon test to find differential expressed column values
get_diff_express <- function(data_scaled, cat_1, cat_2) {
  wilcox_res <- matrix(nrow = ncol(data_scaled), ncol = 1)
  rownames(wilcox_res) <- colnames(data_scaled)
  
  for (i in seq_len(ncol(data_scaled))) {
    val_1 <- as.numeric(data_scaled[grep(cat_1, rownames(scaled_counts)), i])
    val_2 <- as.numeric(data_scaled[grep(cat_2, rownames(scaled_counts)), i])
    wilcox_res[i, 1] <- wilcox.test(val_1, val_2)[[3]]
  }
  
  # apply benjamini hochberg correction to p-values
  wilcox_res[, 1] <- p.adjust(wilcox_res[, 1], method = "BH", 
                              n = length(wilcox_res[, 1]))
  
  # order p-values from lowest to highest
  ordered_res <- wilcox_res
  ordered_res[, 1] <- wilcox_res[order(wilcox_res[, 1]), ]
  rownames(ordered_res) <- rownames(wilcox_res)[order(wilcox_res[, 1])]

  return(ordered_res)
}
