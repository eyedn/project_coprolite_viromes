###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   create_violin.R
###############################################################################
library(ggplot2)
library(svglite)
library(reshape2)
library(latex2exp)


# create a violin plot of paired-clustering tendencies with permutation CI
create_violin <- function(boot_data, perm_data, ci_perc, file_name, 
                          plot_dir, k) {
  melted_data <- as.data.frame(melt(boot_data))
  melted_data$Var2 <- factor(melted_data$Var2)
  custom_labels <- c("Ind. with Ind.", "Pre. with Pre.", "Pal with Pal.",
                    "Ind. with Pal.", "Ind. with Pre.", "Pre. with Pal.")
  
  # get confidence interval from permutation data
  ci <- matrix(nrow = 2, ncol = ncol(perm_data))
  for (i in seq_len(ncol(perm_data))) {
    sorted_perm <- sort(perm_data[, i])
    ci[1, i] <- sorted_perm[ci_perc[1]*length(sorted_perm)]
    ci[2, i] <- sorted_perm[ci_perc[2]*length(sorted_perm)]
  }
  melted_ci <- as.data.frame(melt(ci))
  melted_ci$Var2 <- factor(melted_ci$Var2)
  
  # combine boot strap violin plot with permutation CI
  violin <- ggplot(melted_data, aes(x = Var2, y = value)) +
    geom_violin(aes(fill=Var2)) +
    scale_fill_manual(values = safe_colors[c(1:4, 6, 7)], guide = "none") +
    geom_point(data = melted_ci, size = 5, pch = 23, fill = safe_colors[14],
               stroke = 1, show.legend = FALSE) +
    scale_x_discrete(labels = custom_labels) +
    stat_summary(fun = median, geom = "point", fill = safe_colors[12], 
                 pch = 24, size = 5, stroke = 1) +
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

  print(violin)

  # save image to svg file
  ggsave(filename = paste0(plot_dir, "/", file_name, ".svg"),
         plot = violin,
         height = 10,
         width = 20)
}
