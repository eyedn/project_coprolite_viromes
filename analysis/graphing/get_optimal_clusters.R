###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   get_optimal_clusters.R
###############################################################################
library(ggplot2)
library(factoextra)


get_optimal_clusters <- function(data, method) {
  # find optimal number of clusters with fviz_nbclust function
  clusters <- fviz_nbclust(data, kmeans, nboot = 1000, method = method) +
    labs(subtitle = "Elbow method") +
    theme_bw() +
    theme(
      plot.margin = margin(20, 20, 20, 20, "points"),
      plot.title = element_text(size = 20,
                                face = "bold",
                                margin = margin(t = 0, r = 0, b = 20, l = 0)),
      axis.title.x = element_text(size = 16,
                                  face = "bold",
                                  margin = margin(t = 20, r = 0, b = 0, l = 0)),
      axis.title.y = element_text(size = 16,
                                  face = "bold",
                                  margin = margin(t = 0, r = 20, b = 0, l = 0)),
      axis.text = element_text(size = 16),
      legend.position = "top",
      legend.title = element_text(size = 14),
      legend.text = element_text(size = 12)
    )
  
  return(clusters)
}
