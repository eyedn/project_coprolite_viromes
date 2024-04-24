###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   get_diff_repres_vf.R
###############################################################################
library(stats)
library(reshape2)


# use kruskal-walis test to determine differential repres. of enzymes classes
get_diff_repres_vf <- function(data, vf_reference) {
  value_res <- vector()
  
  melted_data <- as.data.frame(melt(data))
  melted_data[,1] <- substr(melted_data[,1], 1, 3)
  colnames(melted_data) <- c("cat_name", "VFID", "value")
  melted_data$cat_name <- as.character(melted_data$cat_name)
  melted_data$cat_name <- substr(melted_data$cat_name, 0, 3)
  
  melted_data <- merge(melted_data, vf_reference, 
                       by.x = "VFID", by.y = "VFID")
  
  vfc <- unique(melted_data[, "VFcategory"])
  
  for (i in seq_len(length(vfc))) {
    class_subset <- melted_data[melted_data[, "VFcategory"] == vfc[i], ]
    
    if (nrow(class_subset) == 0) {
      next
    } else {
      value_res[i] <- kruskal.test(class_subset$value, class_subset$cat_name)[[3]]
    }
    
    ind_subset <- class_subset[class_subset$cat_name == "ind", ]
    pre_subset <- class_subset[class_subset$cat_name == "pre", ]
    pal_subset <- class_subset[class_subset$cat_name == "pal", ]
    
    ind_subset$value <- abs(ind_subset$value - median(ind_subset$value))
    pre_subset$value <- abs(pre_subset$value - median(pre_subset$value))
    pal_subset$value <- abs(pal_subset$value - median(pal_subset$value))
  }
  
  # apply benjamini hochberg correction to p-values
  value_res <- p.adjust(value_res, method = "BH", n = length(value_res))
  
  for (i in seq_len(length(value_res))) {
    cat(paste0(vfc[i], " results: \n"))
    cat(paste0("\tvalue test: ", value_res[i], " , pass = ",
               ifelse(value_res[i] <= 0.05, TRUE, FALSE), "\n"))
  }
}
