###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   pca_graph_function.R
###############################################################################
library(rcartocolor)
library(ggplot2)
library(svglite)
library(gplots)

# generate safe colors from rcartocolor plus 4 more for all samples origins
safe_colors <- c(carto_pal(12, "Safe"),
                 "#E69F00", "#000000", "#b0f2bc", "#D55E00")
safe_shapes <- c(15, 16, 17, 18, 9, 10, 11, 12, 14)

# label sample categories for facet graph
sample_labels <- c('ind'="Industrial, Modern",
                   'pal'="Paleo-sample",
                   'pre'="Pre-Industrial, Modern")

# create labels for clustering barplot
cluster_labels <- c("Ind. vs. Ind.", "Pre. vs. Pre.", "Pal. vs. Pal.",
                    "Ind. vs. Pal", "Ind. vs. Pre", "Pre. vs. Pal.")

# generate pca plots
pca_plot <- function(df, pca_subset, pc1, pc2, k, type, iter, plot_dir) {
  # Subset the first two principal components
  # pca_subset <- as.data.frame(pca$x[, c(pc1, pc2)])
  pca_subset$cluster <- df[, 1]
  pca_subset$time <- df[, 2]
  pca_subset$origin <- df[, 3]
  colnames(pca_subset) <- c("PC1", "PC2", "cluster", "time", "origin")
  # if this is the first iteration, gerneate the origin plot
  # Plot the origin
  orgin_plot <- ggplot(pca_subset, aes(x = PC1, y = PC2,
                                       color = factor(origin),
                                       shape = factor(time),
                                       size = factor(time))) +
    geom_point() +
    ggtitle(paste0("PCA-reduced Genome Annotation for ",
                   type, " Genes on Viral Contigs")) +
    xlab(paste0("PC", pc1)) +
    ylab(paste0("PC", pc2)) +
    scale_color_manual(name = "Sample Origins",
                       labels = unique(pca_subset$origin),
                       values = safe_colors[1:length(unique(pca_subset$origin))]) +
    scale_size_manual(name = "Sample Time",
                      labels = c("Industrial, Modern",
                                 "Paleo-sample",
                                 "Pre-Industrial, Modern"),
                      values = c(5, 8, 5)) +
    scale_shape_manual(name = "Sample Time",
                       labels = c("Industrial, Modern",
                                  "Paleo-sample",
                                  "Pre-Industrial, Modern"),
                       values = safe_shapes[1:3]) +
    guides(color = guide_legend(override.aes = list(size = 8, pch = 18))) +
    theme(
      plot.title = element_text(size = 20, face = "bold"),
      axis.title.x = element_text(size = 16, face = "bold"),
      axis.title.y = element_text(size = 16, face = "bold"),
      legend.title = element_text(size = 14),
      legend.text = element_text(size = 12)
    )
  print(orgin_plot)
  # ggsave(filename = paste0(plot_dir, "/origin_plot.svg"), orgin_plot,
  #        height = 10,
  #        width = 12)
  # Plot the clusters
  cluster_plot <- ggplot(pca_subset, aes(x = PC1, y = PC2,
                                      color = factor(cluster),
                                      shape = factor(cluster))) +
    geom_point(size = 5) +
    ggtitle(paste0("PCA of Annotation for ",
                   type,
                   " Genes on Viral Contigs 
            with Kmeans Clustering (K = ", k, ", iter. = ", iter, ")")) +
    xlab(paste0("PC", pc1)) +
    ylab(paste0("PC", pc2)) +
    scale_color_manual(name = "Clusters:",
                       labels = as.character(seq(1:k)),
                       values = safe_colors[c(1:k)]) +
    scale_shape_manual(name = "Clusters:",
                       labels = as.character(seq(1:k)),
                       values = safe_shapes[c(1:k)]) +
    theme(
      legend.position = "top",
      plot.title = element_text(size = 20, face = "bold"),
      axis.title.x = element_text(size = 16, face = "bold"),
      axis.title.y = element_text(size = 16, face = "bold"),
      legend.title = element_text(size = 14),
      legend.text = element_text(size = 12)
    ) +
    guides(color = guide_legend(override.aes = list(size = 8)))
  print(cluster_plot)
  # ggsave(filename = paste0(plot_dir, "/cluster_plot_", iter, ".svg"),
  #        plot = cluster_plot,
  #        height = 10,
  #        width = 10)
  # plot clustering with facet by time
  time_plot_facet <- ggplot(pca_subset, aes(x = PC1, y = PC2,
                                            color = factor(cluster),
                                            shape = factor(time))) +
    geom_point(size = 5) +
    ggtitle(paste0("Behaviour of Sample Catagories under Kmeans Clustering (K = ",
                   k,
                   ", iter. = ", iter, ")")) +
    xlab(paste0("PC", pc1)) +
    ylab(paste0("PC", pc2)) +
    scale_color_manual(name = "Clusters:",
                       labels = as.character(seq(1:k)),
                       values = safe_colors[1:k]) +
    scale_shape_manual(name = "Clusters:",
                       labels = as.character(seq(1:k)),
                       values = safe_colors[1:k]) +
    theme_bw() +
    facet_wrap(~time, labeller = as_labeller(sample_labels)) +
    guides(color = guide_legend(override.aes = list(size = 8, pch = 18))) +
    guides(shape = guide_legend(override.aes = list(size = 8))) +
    theme(
      legend.position = "top",
      strip.text = element_text(size = 14),
      plot.title = element_text(size = 20, face = "bold"),
      axis.title.x = element_text(size = 16, face = "bold"),
      axis.title.y = element_text(size = 16, face = "bold"),
      legend.title = element_text(size = 14),
      legend.text = element_text(size = 12)
    )
  print(time_plot_facet)
  # ggsave(filename = paste0(plot_dir, "/time_plot_facet_", iter, ".svg"),
  #        plot = time_plot_facet,
  #        height = 7,
  #        width = 17)
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

# create heat map of differentially expressed genes
heat_plot <- function(heatmap_mat) {
  heat <- heatmap.2(heatmap_mat,
                    trace = "none",
                    col = colorRampPalette(c("blue", "red"))(256),
                    keysize = 1.2, density.info = "none", 
                    key.xlab = "log(CPM + 1)", key.title = "Color  Key",
                    margins = c(14, 12), cexRow = 1.2, cexCol = 1, 
                    xlab = "Something", ylab = "Something",
                    main = "BIG SOMETHING") 
  return(heat)
}