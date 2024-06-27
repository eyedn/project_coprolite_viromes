###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   create_pres_abs_heatmap.R
###############################################################################
library(gplots)
library(svglite)
library(RColorBrewer)
library(dendextend)


# generate a heatmap based on differential expression
create_pres_abs_heatmap <- function(data, lifestyle, file_name, plot_dir) {
  
  # subset data for counts, lifestyle, and category
  cat_vec <- substr(data[, ncol(data)], 1, 3)
  life_vec <- substr(data[, (ncol(data) - 2)], 1, 3)
  data <- data[, -(c(ncol(data) - 2):ncol(data))]
  
  # Define dfs for samples location, category, dend. weight, and side bar color
  sample_loc <- data.frame(
    loc = substr(rownames(data), 1, 7),
    cat = cat_vec,
    life = life_vec
  )
  life_col <- data.frame(
    life = c("Lyt", "Tem"),
    life_col = brewer.pal(7, "PuRd")[c(2,6)]
  )
  cat_weights <- data.frame(
    cat = c("Pal", "Pre", "Ind"),
    weight = c(2, 1, 0)
  )
  cat_cols <- data.frame(
    cat = c("Pal", "Pre", "Ind"),
    cat_col = rev(brewer.pal(9, "Greys")[c(3,5,8)])
  )
  loc_life <- merge_and_retain_order(sample_loc, life_col, "life", "life")
  sample_weights <- merge_and_retain_order(loc_life, cat_weights, "cat", "cat")
  loc_cols <- merge_and_retain_order(loc_life, cat_cols, "cat", "cat")
  
  # Define groups dendrogram order, colors, and labels
  col_hc <- hclust(dist(data))
  col_dend <- as.dendrogram(col_hc)
  group_dend <- reorder(col_dend, wts = sample_weights$weight,
                        agglo.FUN = mean)
  group_col <- loc_cols$cat_col
  lifestyle_col <- loc_cols$life_col

  # define vfc dendrogram, colors, and labels
  row_hc <- hclust(dist(t(data)))
  row_dend <- as.dendrogram(row_hc)
  
  # save group plot to svg file
  file_name <- append_time_to_filename(file_name)
  if (lifestyle == FALSE) {
    svglite(filename = paste0(plot_dir, "/group_", file_name, ".svg"),
            width = 35,
            height = 45)
    
    heatmap.2(t(data),
              trace = "none",
              Colv = group_dend, 
              Rowv = row_dend,
              col = rev(brewer.pal(11, "RdBu"))[c(2,10)],
              srtCol = 325,
              adjCol = c(0, 1),
              ColSideColors = group_col,
              margins = c(40, 35),
              cexRow = 3,
              cexCol = 3.5,
              lhei = c(0.8, 3),
              lwid = c(0.8, 3),
              key = FALSE,
              density.info = "none"
    )
  } else {
    # save lifestyle plot to svg file
    svglite(filename = paste0(plot_dir, "/lifestyle_", file_name, ".svg"),
            width = 35,
            height = 45)
    
    heatmap.2(t(data),
              trace = "none",
              Colv = group_dend, 
              Rowv = row_dend,
              col = rev(brewer.pal(11, "RdBu"))[c(2,10)],
              srtCol = 325,
              adjCol = c(0, 1),
              ColSideColors = lifestyle_col,
              margins = c(40, 35),
              cexRow = 3,
              cexCol = 3.5,
              lhei = c(0.8, 3),
              lwid = c(0.8, 3),
              key = FALSE,
              density.info = "none"
    )
  }
}
