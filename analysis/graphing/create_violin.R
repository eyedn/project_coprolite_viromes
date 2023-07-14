###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   create_violin.R
###############################################################################
library(ggplot2)
library(ggbrace)
library(svglite)
library(reshape2)
library(latex2exp)


# create a violin plot of paired-clustering tendencies with permutation CI
create_violin <- function(boot_data, perm_data, ci_perc, file_name, 
                          plot_dir, k) {
  melted_data <- as.data.frame(melt(boot_data))
  colnames(melted_data) <- c("sample", "pair", "prob")
  melted_data$pair <- factor(melted_data$pair)
  custom_labels <- c("Ind. with Ind.", "Pre. with Pre.", "Pal with Pal.",
                    "Ind. with Pal.", "Ind. with Pre.", "Pre. with Pal.")
  
  # get confidence interval from permutation data
  ci_perm <- matrix(nrow = ncol(perm_data), ncol = 3)
  for (i in seq_len(ncol(perm_data))) {
    ci_perm_sorted <- sort(perm_data[, i])
    ci_perm[i, 1] <- i
    ci_perm[i, 2] <- ci_perm_sorted[ci_perc[1]*length(ci_perm_sorted)]
    ci_perm[i, 3] <- ci_perm_sorted[ci_perc[2]*length(ci_perm_sorted)]
  }
  ci_perm <- as.data.frame(ci_perm)
  colnames(ci_perm) <- c("group", "lower", "upper")
  melted_perm <- as.data.frame(melt(perm_data))
  colnames(melted_perm) <- c("sample", "pair", "prob")
  melted_perm$pair <- factor(melted_perm$pair)
  
  # combine boot strap violin plot with permutation CI
  violin <- ggplot(melted_data, aes(x = pair, y = prob)) +
    geom_violin(aes(fill = pair), trim = FALSE) +
    # geom_violin(data = melted_perm, aes(x = pair, y = prob), trim = TRUE,
    #             inherit.aes = FALSE) +
    scale_fill_manual(values = safe_colors[c(1:4, 6, 7)], guide = "none") +
    geom_errorbar( mapping = aes(x = group, ymin = lower, ymax = upper),
                   data = ci_perm, width = 0.4, size = 1.25,
                   color = safe_colors[14], inherit.aes = FALSE) +
    scale_x_discrete(labels = custom_labels) +
    stat_summary(data = melted_data, aes(x = pair, y = prob), 
                 fun = median, geom = "point", fill = safe_colors[12], 
                 color = safe_colors[14], pch = 23, size = 5, stroke = 1,
                 inherit.aes = FALSE) +
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

  # save image to svg file
  ggsave(filename = paste0(plot_dir, "/", file_name, ".svg"),
         plot = violin,
         height = 10,
         width = 20)
  
  return(violin)
}
