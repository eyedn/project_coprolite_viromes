###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   create_facet_clusters_mds.R
###############################################################################
library(ggplot2)
library(svglite)


# create mds plot that creates separate panels for each category
create_facet_clusters_mds <- function(meta_data, mds, k, iter, plot_dir) {
  mds$cluster <- meta_data[, 1]
  mds$time <- meta_data[, 2]
  mds$origin <- meta_data[, 3]
  colnames(mds) <- c("MDS1", "MDS2", "cluster", "time", "origin")

  # plot with ggplot2
  time_plot_facet <- ggplot(mds, aes(x = MDS1, y = MDS2,
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
    facet_wrap(~time, labeller = as_labeller(sample_labels)) +
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
  
  print(time_plot_facet)
  
  # save image to svg file
  ggsave(filename = paste0(plot_dir, "/time_plot_facet_", iter, ".svg"),
         plot = time_plot_facet,
         height = 8,
         width = 15)
}
