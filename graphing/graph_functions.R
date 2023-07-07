###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   graph_function.R
###############################################################################
library(rcartocolor)
library(ggplot2)
library(svglite)
library(gplots)
library(reshape2)
library(ggbeeswarm)
library(latex2exp)
library(maps)

# generate safe colors from rcartocolor plus 4 more for all samples origins
safe_colors <- c(carto_pal(12, "Safe"),
                 "#E69F00", "#000000", "#b0f2bc", "#D55E00")
safe_shapes <- c(15, 16, 17, 18, 9, 10, 11, 12, 14)

# label sample categories for facet graph
sample_labels <- c('ind'="Modern, Industrial",
                   'pal'="Paleo-sample",
                   'pre'="Modern, Pre-Industrial")

# create labels for clustering barplot
cluster_labels <- c("Ind. vs. Ind.", "Pre. vs. Pre.", "Pal. vs. Pal.",
                    "Ind. vs. Pal", "Ind. vs. Pre", "Pre. vs. Pal.")

# generate plot to find optimal clusters
num_clusters <- function(data, method) {
  num_clu <- fviz_nbclust(data, kmeans, method = method) +
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
      axis.text=element_text(size=16), 
      legend.position = "top",
      legend.title = element_text(size = 14),
      legend.text = element_text(size = 12)
    )
  return(num_clu)
}

# generate mds plots
mds_plot <- function(meta_data, mds, k, iter, seed, plot_dir) {
  mds$cluster <- meta_data[, 1]
  mds$time <- meta_data[, 2]
  mds$origin <- meta_data[, 3]
  colnames(mds) <- c("MDS1", "MDS2", "cluster", "time", "origin")
  # if this is the first iteration, gerneate the origin plot
  # Plot the categories
  orgin_plot <- ggplot(mds, aes(x = MDS1, y = MDS2,
                                color = factor(time),
                                shape = factor(time),
                                size = factor(time))) +
    geom_point() +
    ggtitle(paste0("iter. = ", iter, ", seed = ", seed)) +
    xlab("MDS1") +
    ylab("MDS2") +
    scale_size_manual(guide = "none",
                      values = c(5, 8, 5)) +
    scale_shape_manual(guide = "none",
                       values = safe_shapes[1:3]) +
    scale_color_manual(guide = "none",
                       values = safe_colors[1:3]) +
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
      axis.text=element_text(size=28), 
      strip.text.x = element_text(size = 28),
    )
  print(orgin_plot)
  ggsave(filename = paste0(plot_dir, "/category_plot_", iter, ".svg"), 
         plot = orgin_plot,
         height = 8,
         width = 8)
  # Plot the clusters
  cluster_plot <- ggplot(mds, aes(x = MDS1, y = MDS2,
                                      color = factor(cluster),
                                      shape = factor(cluster))) +
    geom_point(size = 5) +
    ggtitle(paste0("k = ", k, ", iter. = ", iter, ", seed = ", seed)) +
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
      axis.text=element_text(size=28), 
      strip.text.x = element_text(size = 28),
    )
  print(cluster_plot)
  ggsave(filename = paste0(plot_dir, "/cluster_plot_", iter, ".svg"),
         plot = cluster_plot,
         height = 8,
         width = 8)
  # plot clustering with facet by time
  time_plot_facet <- ggplot(mds, aes(x = MDS1, y = MDS2,
                                     color = factor(cluster),
                                     shape = factor(cluster))) +
    geom_point(size = 5) +
    ggtitle(paste0("k = ", k, ", iter. = ", iter, ", seed = ", seed)) +
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
      axis.text=element_text(size=28), 
      strip.text.x = element_text(size = 28),
    )
  print(time_plot_facet)
  ggsave(filename = paste0(plot_dir, "/time_plot_facet_", iter, ".svg"),
         plot = time_plot_facet,
         height = 8,
         width = 15)
}

# create barplot of average percent clustering
clus_plot <- function(av_kmeans_data, plot_dir) {
  # Create a data frame with the data and labels
  df <- data.frame(data = av_kmeans_data, labels = cluster_labels)
  # Round the data values to three decimal places
  df$data <- round(df$data, 3)
  # Create the bar plot
  clus_barplot <- ggplot(df, aes(x = labels, y = data, fill = as.factor(labels))) +
    geom_bar(stat = "identity") +
    geom_text(aes(label = data), vjust = -0.5) +
    scale_fill_manual(values = safe_colors)
  # display plot
  return(clus_barplot)
  ggsave(filename = paste0(plot_dir, "/clus_barplot.svg"),
         plot = clus_barplot)
}

# create a beeswarms plot of paired-cluserting tendencies
bee_plot <- function(iterative_data, plot_dir, k) {
  melted_data <- as.data.frame(melt(iterative_data))
  melted_data$Var2 <- factor(melted_data$Var2)
  custom_labels = c("Ind. with Ind.", "Pre. with Pre.", "Pal with Pal.", 
                    "Ind. with Pal.", "Ind. with Pre.", "Pre. with Pal.")
  bee <- ggplot(melted_data, aes(x=Var2, y=value)) +
    geom_hline(yintercept = 1/k, 
               linewidth = 2, color = safe_colors[12]) +
    geom_beeswarm(size = 3, cex = .8, dodge.width = 1, aes(color=Var2)) +
    stat_summary(fun=median, geom='point', fill = safe_colors[12], 
                 pch = 24, size = 5, stroke = 1) +
    scale_color_manual(values = safe_colors[c(1:4,6,7)], guide = "none") +
    scale_x_discrete(labels = custom_labels) +
    labs(x = paste0("Randomly Chosen Sample Pair given Categories (", 
                    TeX("$C_i$"), " with ", TeX("$C_j"), ")"), 
         y = "P(Same Cluster | Pair)",
         title = "Clustering Probability of a Pair of Randomly-Chosen Samples") +
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
      axis.text=element_text(size=28), 
      legend.position = "top",
      legend.title = element_text(size = 24),
      legend.text = element_text(size = 24)
    )
  ggsave(filename = paste0(plot_dir, "/clus_probs", ".svg"),
         plot = bee,
         height = 10,
         width = 20)
  return(bee)
}

# return a map with coutries where samples come from filled in with a color
colored_samples_map <- function() {
  # print map of samples:
  thismap <- map_data("world")
  # Set colors
  thismap$fill <- ifelse(thismap$region %in% c("Spain", "Denmark"), safe_colors[1],
                         ifelse(thismap$region %in% c("Fiji", "Madagascar", "Tanzania"), safe_colors[2],
                                ifelse(thismap$region %in% c("Belgium", "England", "South Africa", "Italy"), safe_colors[3],
                                       ifelse(thismap$region %in% c("USA"), safe_colors[4],
                                              ifelse(thismap$region %in% c("Mexico", "Peru"), safe_colors[6], "white")))))
  
  # Use scale_fill_manual to set correct colors
  samples <- ggplot(thismap, aes(long, lat, fill = fill, group = group)) +
    geom_polygon(colour = "gray") +
    ggtitle("Map of Samples") +
    scale_fill_identity() +
    theme_bw() +
    theme(
      plot.margin = margin(20, 20, 20, 20, "points"),
      plot.title = element_text(size = 20, 
                                face = "bold", 
                                margin = margin(t = 0, r = 0, b = 20, l = 0)),
      axis.title.x = element_blank(),
      axis.title.y = element_blank(),
      axis.text=element_blank(),
      legend.position = "top",
      legend.title = element_text(size = 14),
      legend.text = element_text(size = 12)
    )
  return(samples)
}
