###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   create_beeswarm.R
###############################################################################
library(ggplot2)
library(svglite)
library(ggbeeswarm)
library(reshape2)
library(latex2exp)


# create a beeswarms plot of paired-cluserting tendencies
create_beeswarm <- function(data, file_name, plot_dir, k) {
  melted_data <- as.data.frame(melt(data))
  melted_data$Var2 <- factor(melted_data$Var2)
  custom_labels <- c("Ind. with Ind.", "Pre. with Pre.", "Pal with Pal.",
                    "Ind. with Pal.", "Ind. with Pre.", "Pre. with Pal.")
  bee <- ggplot(melted_data, aes(x = Var2, y = value)) +
    geom_beeswarm(size = 3, cex = .8, dodge.width = 1, aes(color = Var2)) +
    stat_summary(fun = median, geom = "point", fill = safe_colors[12], 
                 pch = 24, size = 5, stroke = 1) +
    scale_color_manual(values = safe_colors[c(1:4, 6, 7)], guide = "none") +
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
      axis.text = element_text(size = 28),
      legend.position = "top",
      legend.title = element_text(size = 24),
      legend.text = element_text(size = 24)
    )
  
  print(bee)
  
  # save image to svg file
  ggsave(filename = paste0(plot_dir, "/", file_name, ".svg"),
         plot = bee,
         height = 10,
         width = 20)
}
