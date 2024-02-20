###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   create_heatmap.R
###############################################################################
library(gplots)
library(svglite)
library(RColorBrewer)
library(dendextend)


# generate a heatmap based on differential expression
create_metabolic_heatmap <- function(data, signif_res, subset,
                                     file_name, plot_dir) {
  
  sig_data <- data[, rownames(signif_res)[1:subset]]
  
  sig_data_concat <- matrix(ncol = ncol(sig_data), nrow = length(cat_labels))
  colnames(sig_data_concat) <- colnames(sig_data)
  rownames(sig_data_concat) <- cat_labels
  
  # combine all data from same category by taking median
  for (i in seq_len(length(cat_labels))) {
    cat_subset <- sig_data[grep(cat_labels[i], rownames(sig_data)), ]
    
    if (is.matrix(cat_subset)) {
      cat_stats <- apply(cat_subset, 2, median)
    } else {
      cat_stats <- as.vector(cat_subset)
    }
    
    sig_data_concat[cat_labels[i], ] <- cat_stats
  }
  
  # define dendrogram order
  dend_width <- 15
  hc <- hclust(dist(sig_data_concat))
  dend_raw <- as.dendrogram(hc)
  dend <- set(dend_raw, "branches_lwd", dend_width)
  weights <- c()
  groups <- rownames(sig_data_concat)
  for (i in seq_len(length(groups))) {
    if (grepl("pal", groups[i])) {
      weights <- c(weights, 0)
    } else if (grepl("pre", groups[i])) {
      weights <- c(weights, 1)
    } else if (grepl("ind", groups[i])) {
      weights <- c(weights, 2)
    } else {
      weights <- c(weights, 3)
    }
  }
  reordered_dend <- reorder(dend, wts = weights, agglo.FUN = mean)
  
  hc_2 <- hclust(dist(t(sig_data_concat)))
  dend_raw_2 <- as.dendrogram(hc_2)
  dend_2 <- set(dend_raw_2, "branches_lwd", dend_width)
  
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
  file_name <- append_time_to_filename(file_name)
  svglite(filename = paste0(plot_dir, "/", file_name, ".svg"),
          width = 35,
          height = 45)
  
  heatmap.2(t(sig_data_concat),
            trace = "none",
            Colv = reordered_dend, 
            Rowv = dend_2,
            col = rev(brewer.pal(11, "RdBu")),
            srtCol = 325,
            adjCol = c(0, 1),
            ColSideColors = group_col,
            labCol = col_labels,
            RowSideColors = ec_col,
            margins = c(25, 20),
            cexRow = 3,
            cexCol = 3.5,
            lhei = c(0.8, 3),
            lwid = c(0.8, 3),
            key = TRUE,
            key.xlab = "scaled log(CPM + 1)",
            key.title = "Median EC Representation",
            keysize = 2,
            key.par = list(cex = 3),
            density.info = "none"
  )
}
