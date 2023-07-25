###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   create_violin.R
###############################################################################
library(ggplot2)
library(ggsignif)
library(patchwork)
library(RColorBrewer)
library(svglite)
library(reshape2)


# create a violin plot of paired-clustering tendencies with permutation CI
create_violin <- function(boot_data, clus_res, file_name, plot_dir) {
  # create plot for wither homogeneous pairings or heterogeneous pairings
  custom_labels <- c("Ind. with Ind.",
                     "Pre. with Pre.",
                     "Pal. with Pal.",
                     "Ind. with Pal.",
                     "Ind. with Pre.",
                     "Pre. with Pal.") 
  
  melted_data <- as.data.frame(melt(boot_data))
  colnames(melted_data) <- c("sample", "pair", "prob")
  
  # get confidence interval from permutation data
  ci <- matrix(nrow = length(clus_res), ncol = 3)
  for (i in seq_len(length(clus_res))) {
    if (i <= 3) {
      ci[i, 1] <- i
    } else {
      ci[i, 1] <- i - 3 
    }
    ci[i, 2] <- clus_res[[i]][[2]][1, 3]
    ci[i, 3] <- clus_res[[i]][[2]][2, 3]
  }
  ci <- as.data.frame(ci)
  colnames(ci) <- c("group", "lower", "upper")
  
  # generate graph for homogenous pairs
  melted_homo <- melted_data[melted_data$pair <= 3, , drop = FALSE]
  melted_homo$pair <- factor(melted_homo$pair)
  
  homo_violin <- ggplot(melted_homo, aes(y = prob)) +
    geom_violin(aes(x = pair, fill = pair), color = brewer.pal(9, "Greys")[8],
                linewidth = 1, trim = TRUE) +
    scale_fill_manual(values = replicate(3, brewer.pal(9, "Greys")[2]),
                      guide = "none") +
    geom_errorbar(mapping = aes(x = group, ymin = lower, ymax = upper),
                  data = ci[4:6, ], width = 0.7, size = 1, 
                  color = brewer.pal(11, "RdBu")[10], inherit.aes = FALSE) +
    annotate("text", label = "***", x = 1, y = max(boot_data[, 1]) + 0.01,
             size = 12, color = brewer.pal(9, "Greys")[8]) +
    stat_summary(aes(x = pair, y = prob), fun = median, geom = "point", 
                 fill = brewer.pal(9, "Greys")[8], pch = 23, size = 6,
                 stroke = 1, inherit.aes = FALSE) +
    labs(x = "Homogenous Cartegory Pairings") +
    scale_x_discrete(labels = custom_labels[c(1:3)]) +
    scale_y_continuous(name = "P(Same Cluster | Pair)", limits = c(0, 1.05),
                       breaks = c(0, 0.25, 0.5, 0.75, 1)) +
    theme_bw() +
    theme(
      plot.margin = margin(20, 5, 20, 20, "points"),
      axis.title.x = element_text(size = 18,
                                  face = "bold",
                                  margin = margin(t = 20, r = 0, b = 0, l = 0)),
      axis.title.y = element_text(size = 18,
                                  face = "bold",
                                  margin = margin(t = 0, r = 20, b = 0, l = 0)),
      axis.text = element_text(size = 14),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      axis.ticks.x = element_blank()
    )

  # generate graph for heterogeneous pairs
  melted_hete <- melted_data[melted_data$pair > 3, , drop = FALSE]
  melted_hete$pair <- factor(melted_hete$pair)
  
  hete_violin <- ggplot(melted_hete, aes(y = prob)) +
    geom_violin(aes(x = pair, fill = pair), color = brewer.pal(9, "Greys")[8],
                linewidth = 1, trim = TRUE) +
    scale_fill_manual(values = replicate(3, brewer.pal(9, "Greys")[2]),
                      guide = "none") +
    geom_errorbar(mapping = aes(x = group, ymin = lower, ymax = upper),
                  data = ci[4:6, ], width = 0.7, size = 1, 
                  color = brewer.pal(11, "RdBu")[10], inherit.aes = FALSE) +
    annotate("text", label = "****", x = 1, y = max(boot_data[, 4]) + 0.01,
             size = 12, color = brewer.pal(9, "Greys")[8]) +
    stat_summary(aes(x = pair, y = prob), fun = median, geom = "point", 
                 fill = brewer.pal(9, "Greys")[8], pch = 23, size = 6,
                 stroke = 1, inherit.aes = FALSE) +
    labs(x = "Heterogeneous Cartegory Pairings") +
    scale_x_discrete(labels = custom_labels[c(4:6)]) +
    scale_y_continuous(name = "P(Same Cluster | Pair)", limits = c(0, 1.05),
                       breaks = c(0, 0.25, 0.5, 0.75, 1)) +
    theme_bw() +
    theme(
      plot.margin = margin(20, 20, 20, 5, "points"),
      axis.title.x = element_text(size = 18,
                                  face = "bold",
                                  margin = margin(t = 20, r = 0, b = 0, l = 0)),
      axis.text = element_text(size = 14),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      axis.ticks.x = element_blank(),
      title = element_blank(),
      axis.title.y.left = element_blank(),
      axis.text.y.left = element_blank(),
    )
  
  violin <- homo_violin + hete_violin + plot_annotation(
    title = "Clustering Probability of Samples by Gene Representation",
    theme = theme(plot.title = element_text(size = 24, 
                                            face = "bold"))
  )
  
  # save image to svg file
  ggsave(filename = paste0(plot_dir, "/", file_name, ".svg"),
         plot = violin,
         height = 8,
         width = 14)
  
  return(violin)
}
