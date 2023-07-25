###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   get_diff_repres_class.R
###############################################################################
library(stats)
library(reshape2)


# use kruskal-walis test to determine differential repres. of enzymes classes
get_diff_repres_class <- function(data) {
  value_res <- vector(length = 7)
  spread_res <- vector(length = 7)
  
  for (i in seq_len(7)) {
    class_subset <- data[, startsWith(colnames(data), as.character(i))]
    class_subset <- melt(class_subset)
    colnames(class_subset) <- c("sample", "ec", "value")
    class_subset$sample <- substr(class_subset$sample, 0, 3)
    
    value_res[i] <- kruskal.test(class_subset$value, class_subset$sample)[[3]]
    
    class_subset$value <- abs(class_subset$value - median(class_subset$value))
    spread_res[i] <- kruskal.test(class_subset$value, class_subset$sample)[[3]]
  }
  
  # apply benjamini hochberg correction to p-values
  value_res <- p.adjust(value_res, method = "BH", n = length(value_res))
  spread_res <- p.adjust(spread_res, method = "BH", n = length(spread_res))
  
  for (i in seq_len(7)) {
    cat(paste0("ec", i, " value result: ", value_res[i], " , pass = ",
               ifelse(value_res[i] <= 0.05, TRUE, FALSE), "\n"))
    cat(paste0("ec", i, " spread result: ", spread_res[i], " , pass = ",
               ifelse(spread_res[i] <= 0.05, TRUE, FALSE), "\n"))
  }
}
