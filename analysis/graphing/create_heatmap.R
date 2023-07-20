###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   create_heatmap.R
###############################################################################
library(gplots)
library(svglite)
library(RColorBrewer)

# generate a heatmap based on differential expression
create_heatmap <- function(data, kruskal_res, color_range, max_items, 
                           file_name, plot_dir) {
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
  weights <- c()
  groups <- rownames(sig_data_concat)
  for (i in seq_len(length(groups))) {
    if (grepl("pal", groups[i])) {
      weights <- c(weights, 4)
    } else if (grepl("MEX", groups[i])) {
      weights <- c(weights, 2)
    } else if (grepl("pre", groups[i])) {
      weights <- c(weights, 3)
    } else if (grepl("ind", groups[i])) {
      weights <- c(weights, 1)
    } else {
      weights <- c(weights, 0)
    }
  }
  reordered_dend <- reorder(row_dend, wts = weights, agglo.FUN = mean)
  
  # define column colors and labels
  group_col_set <- rev(brewer.pal(9, "Greys")[c(3,5,8)])
  group_col <- c()
  col_labels <- c()
  for (i in seq_len(length(groups))) {
    if (grepl("pal", groups[i])) {
      group_col <- c(group_col, group_col_set[1])
    } else if (grepl("pre", groups[i])) {
      group_col <- c(group_col, group_col_set[2])
    } else {
      group_col <- c(group_col, group_col_set[3])
    }
    col_labels <- c(col_labels, origin_labels[[groups[i]]])
  }
  
  # define row colors
  ec_col_set <- brewer.pal(7, "PuRd")
  ecs <- colnames(sig_data_concat)
  ec_col <- c()
  for (i in seq_len(length(ecs))) {
    if (startsWith(ecs[i], "1.")) {
      ec_col <- c(ec_col, ec_col_set[1])
    } else if (startsWith(ecs[i], "2.")) {
      ec_col <- c(ec_col, ec_col_set[2])
    } else if (startsWith(ecs[i], "3.")) {
      ec_col <- c(ec_col, ec_col_set[3])
    } else if (startsWith(ecs[i], "4.")) {
      ec_col <- c(ec_col, ec_col_set[4])
    } else if (startsWith(ecs[i], "5.")) {
      ec_col <- c(ec_col, ec_col_set[5])
    } else if (startsWith(ecs[i], "6.")) {
      ec_col <- c(ec_col, ec_col_set[6])
    } else {
      ec_col <- c(ec_col, ec_col_set[7])
    } 
  }
  
  # save plot to svg file
  svglite(filename = paste0(plot_dir, "/", file_name, ".svg"),
          width = 25,
          height = 35)
  heat <- heatmap.2(t(sig_data_concat),
                    trace = "none",
                    Colv = reordered_dend, 
                    col = rev(brewer.pal(11, "RdBu")),
                    key.xlab = "scaled log(CPM + 1)",
                    key.title = "Median EC Representation",
                    ylab = "EC Enzymes",
                    xlab = "Sample Groups",
                    srtCol = 45,
                    adjCol = c(1, 0.5),
                    ColSideColors = group_col,
                    labCol = col_labels,
                    RowSideColors = ec_col,
                    main = "Differentially Represented Viral Metabolic Genes across Sample Groups",
                    margins = c(15, 10),
                    cexRow = 2,
                    cexCol = 3,
                    keysize = 1, 
                    key.par = list(cex = 1.5),
                    density.info = "none")
  dev.off()
  
  return(heat)
}
