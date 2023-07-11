###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   create_comb_clusters_mds.R
###############################################################################
library(ggplot2)
library(svglite)


# create mds plot that displays all points distinguished by cluster
create_comb_clusters_mds <- function(meta_data, mds, k, iter, plot_dir) {
  mds$cluster <- meta_data[, 1]
  mds$time <- meta_data[, 2]
  mds$origin <- meta_data[, 3]
  colnames(mds) <- c("MDS1", "MDS2", "cluster", "time", "origin")

  # plot with ggplot2
  cluster_plot <- ggplot(mds, aes(x = MDS1, y = MDS2,
                                      color = factor(cluster),
                                      shape = factor(cluster))) +
    geom_point(size = 5) +
    ggtitle(paste0("k = ", k, ", iter. = ", iter)) +
    xlab("MDS1") +
    ylab("MDS2") +
    scale_color_manual(guide = "none",
                       values = safe_colors[c(1:k)]) +
    scale_shape_manual(guide = "none",
                       values = safe_shapes[c(1:k)]) +
    theme_bw() +
    theme(
      plot.margin = margin(20, 20, 20, 20, "points"),
      plot.title = element_text(size = 32,
                                face = "bold",
                                margin = margin(t = 0, r = 0, b = 20, l = 0)),
      axis.title.x = element_text(size = 28,
                                  face = "bold",
                                  margin = margin(t = 20, r = 0, b = 0, l = 0)),
      axis.title.y = element_text(size = 28,
                                  face = "bold",
                                  margin = margin(t = 0, r = 20, b = 0, l = 0)),
      axis.text = element_text(size = 28),
      strip.text.x = element_text(size = 28),
    )
  
  print(cluster_plot)
  
  # save image to svg file
  ggsave(filename = paste0(plot_dir, "/cluster_plot_", iter, ".svg"),
         plot = cluster_plot,
         height = 8,
         width = 8)
}
