###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   create_heatmap.R
###############################################################################
library(gplots)
library(svglite)


# generate a heatmap based on differential expression
create_heatmap <- function(data, kruskal_res, max_items, file_name, plot_dir) {
  sig_data <- data[, rownames(kruskal_res)[1:max_items]]

  ind <- c("ind.DNK", "ind.ESP", "ind.USA")
  pre <- c("pre.FJI", "pre.MDG", "pre.MEX", "pre.PER", "pre.TZA")
  pal <- c("pal.AWC", "pal.BEL", "pal.BMS", "pal.ENG", "pal.ZAF", "pal.ZAP")
  cat <- c(ind, pre, pal)
  
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
  
  # define row dendrogram order
  row_hc <- hclust(dist(sig_data_concat))
  row_dend <- as.dendrogram(row_hc)
  weights <- ifelse(grepl("pal", rownames(sig_data_concat)), 4,
                    ifelse(grepl("MEX", rownames(sig_data_concat)), 2, 
                           ifelse(grepl("pre", rownames(sig_data_concat)), 3,
                                  ifelse(grepl("ind", rownames(sig_data_concat)), 1, 
                                         0))))
  
  reordered_dend <- reorder(row_dend, wts = weights, agglo.FUN = mean)
  
  
  # save plot to svg file
  color_range = 10
  svglite(filename = paste0(plot_dir, "/", file_name, ".svg"),
          width = 20,
          height = 10)
  heat <- heatmap.2(sig_data_concat, trace = "none",
                    Rowv = reordered_dend, 
                    col = colorRampPalette(c("blue", "red"))(color_range),
                    key.xlab = "scaled log(CPM + 1)",
                    key.title = "Median EC Representation of Group",
                    xlab = "EC Enzymes",
                    ylab = "Sample Groups (category-location)",
                    main = "Differentially Represented Viral Metabolic Genes across Sample Groups",
                    margins = c(10, 10),
                    cexRow = 1, cexCol = 1, keysize = 1,
                    density.info = "none")
  dev.off()
  return(heat)
}
