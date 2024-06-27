###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   create_phyla_heatmap.R
###############################################################################
library(gplots)
library(svglite)
library(RColorBrewer)
library(dendextend)


# generate a heatmap based on differential expression
create_phyla_heatmap <- function(data, signif_res, subset,
                                     file_name, plot_dir) {
  
  sig_data <- data[, rownames(signif_res)[1:subset]]
  
  sig_data_concat <- matrix(ncol = ncol(sig_data), nrow = length(cat_labels))
  colnames(sig_data_concat) <- colnames(sig_data)
  rownames(sig_data_concat) <- cat_labels
  
  # Combine all data from same category by taking median
  for (i in seq_len(length(cat_labels))) {
    cat_subset <- sig_data[grep(cat_labels[i], rownames(sig_data)), ]
    
    if (is.matrix(cat_subset)) {
      cat_stats <- apply(cat_subset, 2, median)
    } else {
      cat_stats <- as.vector(cat_subset)
    }
    
    sig_data_concat[cat_labels[i], ] <- cat_stats
  }
  
  # Remove rows where all values are NA
  sig_data_concat <- sig_data_concat[
    rowSums(is.na(sig_data_concat)) != ncol(sig_data_concat), 
  ]
  
  # Define dfs for samples location, category, dend. weight, and side bar color
  sample_loc <- data.frame(
    loc = rownames(sig_data_concat),
    cat = substr(rownames(sig_data_concat), 1, 3)
  )
  cat_weights <- data.frame(
    cat = c("pal", "pre", "ind"),
    weight = c(2, 1, 0)
  )
  cat_cols <- data.frame(
    cat = c("pal", "pre", "ind"),
    col = rev(brewer.pal(9, "Greys")[c(3,5,8)])
  )
  sample_weights <- merge_and_retain_order(sample_loc, cat_weights, "cat", "cat")
  loc_cols <- merge_and_retain_order(sample_loc, cat_cols, "cat", "cat")
  
  # Define groups dendrogram order, colors, and labels
  dend_width <- 15
  hc <- hclust(dist(sig_data_concat))
  dend_raw <- as.dendrogram(hc)
  dend <- dendextend::set(dend_raw, "branches_lwd", dend_width)
  group_dend <- reorder(dend, wts = sample_weights$weight, agglo.FUN = mean)
  group_col <- loc_cols$col
  group_labels <- loc_cols$loc
  
  # Define phyla dendrogram
  hc_2 <- hclust(dist(t(sig_data_concat)))
  dend_raw_2 <- as.dendrogram(hc_2)
  phyla_dend <- dendextend::set(dend_raw_2, "branches_lwd", dend_width)
  
  # Save plot to svg file
  file_name <- append_time_to_filename(file_name)
  svglite(filename = paste0(plot_dir, "/", file_name, ".svg"),
          width = 45,
          height = 35)
  
  heatmap.2(sig_data_concat,
            trace = "none",
            Colv = phyla_dend,
            Rowv = group_dend,
            col = rev(brewer.pal(11, "RdBu")),
            srtCol = 270,
            adjCol = c(0, 1),
            labRow = group_labels,
            RowSideColors = group_col,
            margins = c(25, 20),
            cexRow = 5,
            cexCol = 3,
            lhei = c(0.8, 3),
            lwid = c(0.8, 3),
            key = TRUE,
            key.xlab = "scaled log(CPM + 1)",
            key.title = "Median EC Representation",
            keysize = 2,
            key.par = list(cex = 3),
            density.info = "none",
            add.expr = abline(v=41.5, h = c(3.5, 8.5))
  )
}
