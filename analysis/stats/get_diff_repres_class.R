###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   get_diff_repres_class.R
###############################################################################
library(stats)
library(reshape2)


# use kruskal-walis test to determine differential repres. of enzymes classes
get_diff_repres_class <- function(data) {
  value_res <- vector()
  spread_res <- vector()
  
  for (i in seq_len(7)) {
    class_subset <- data[, startsWith(colnames(data), as.character(i)),
                         drop = FALSE]
    class_subset <- melt(class_subset)
    colnames(class_subset) <- c("sample", "ec", "value")
    class_subset$sample <- substr(class_subset$sample, 0, 3)
    
    if (nrow(class_subset) == 0) {
      next
    } else {
      value_res[i] <- kruskal.test(class_subset$value, class_subset$sample)[[3]]
    }
    
    ind_subset <- class_subset[class_subset$sample == "ind", ]
    pre_subset <- class_subset[class_subset$sample == "pre", ]
    pal_subset <- class_subset[class_subset$sample == "pal", ]
    
    ind_subset$value <- abs(ind_subset$value - median(ind_subset$value))
    pre_subset$value <- abs(pre_subset$value - median(pre_subset$value))
    pal_subset$value <- abs(pal_subset$value - median(pal_subset$value))
    
    spread_res[i] <- kruskal.test(c(ind_subset$value,
                                    pre_subset$value,
                                    pal_subset$value),
                                  c(ind_subset$sample,
                                    pre_subset$sample,
                                    pal_subset$sample))[[3]]
  }
  
  # apply benjamini hochberg correction to p-values
  value_res <- p.adjust(value_res, method = "BH", n = length(value_res))
  spread_res <- p.adjust(spread_res, method = "BH", n = length(spread_res))
   
  for (i in seq_len(length(value_res))) {
    cat(paste0("ec", i, " results: \n"))
    cat(paste0("\tvalue test: ", value_res[i], " , pass = ",
               ifelse(value_res[i] <= 0.05, TRUE, FALSE), "\n"))
    cat(paste0("\tspread test: ", spread_res[i], " , pass = ",
               ifelse(spread_res[i] <= 0.05, TRUE, FALSE), "\n"))
  }
}
