###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   get_diff_repres_ec.R
###############################################################################
library(stats)


# applies a kruskal-walis test to find differential expressed column values
get_diff_repres_ec <- function(data) {
  kruskal_res <- matrix(nrow = ncol(data), ncol = 1)
  rownames(kruskal_res) <- colnames(data)
  
  # create vector of groups for kruskal wallis test
  groups <- vector(length = nrow(data))
  samples <- rownames(data)
  for (i in seq_len(length(samples))) {
    if (grepl("ind", samples[i], fixed = TRUE)) {
      groups[i] = 1
    } else if (grepl("pre", samples[i], fixed = TRUE)) {
      groups[i] = 2
    } else if (grepl("pal", samples[i], fixed = TRUE)) {
      groups[i] = 3
    } else {
      stop(paste0("invalid group at sample ", i))
    }
  } 
  
  for (i in seq_len(ncol(data))) {
    kruskal_res[i, 1] <- kruskal.test(data[, i], groups)[[3]]
  }
  
  # apply benjamini hochberg correction to p-values
  kruskal_res[, 1] <- p.adjust(kruskal_res[, 1], method = "BH", 
                              n = length(kruskal_res[, 1]))
  
  # order p-values from lowest to highest
  ordered_res <- kruskal_res
  ordered_res[, 1] <- kruskal_res[order(kruskal_res[, 1]), ]
  rownames(ordered_res) <- rownames(kruskal_res)[order(kruskal_res[, 1])]

  return(ordered_res)
}
