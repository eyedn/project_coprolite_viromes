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
create_vf_heatmap <- function(data, signif_res, subset, vfc_subset, 
                              vfc_max_colors, file_name, plot_dir) {
  
  sig_data <- data[, signif_res[c(1:subset), "VFID"]]
  
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
  dend <- dendextend::set(dend_raw, "branches_lwd", dend_width)
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
  dend_2 <- dendextend::set(dend_raw_2, "branches_lwd", dend_width)
  
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
  
  # define row colors and labels
  row_col_range <- brewer.pal(vfc_max_colors, "PuRd")
  vfc_subset$color <- 1
  for (i in seq_len(nrow(vfc_subset))) {
    if (i < vfc_max_colors) {
      vfc_subset[i, "color"] <- vfc_max_colors + 1 - i
    } else {
      break
    }
  }
  rownames(vfc_subset) <- vfc_subset[, "Var1"]
  
  row_col <- c()
  for (i in seq_len(subset)) {
    row_col <- c(row_col,
                 row_col_range[vfc_subset[signif_res[i, "VFCID"], "color"]]
                 )
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
            RowSideColors = row_col,
            labCol = col_labels,
            margins = c(25, 20),
            cexRow = 3,
            cexCol = 3.5,
            lhei = c(0.8, 3),
            lwid = c(0.8, 3),
            key = TRUE,
            key.xlab = "scaled log(CPM + 1)",
            key.title = "Median Representation",
            keysize = 2,
            key.par = list(cex = 3),
            density.info = "none"
  )
}
