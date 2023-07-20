###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   create_violin.R
###############################################################################
library(ggplot2)
library(ggsignif)
library(RColorBrewer)
library(svglite)
library(reshape2)
library(latex2exp)


# create a violin plot of paired-clustering tendencies with permutation CI
create_violin <- function(boot_data, perm_data, ci_perc, show_ci, file_name, 
                          plot_dir, k) {
  melted_data <- as.data.frame(melt(boot_data))
  colnames(melted_data) <- c("sample", "pair", "prob")
  melted_data$pair <- factor(melted_data$pair)
  custom_labels <- c("Ind. with Ind.", "Pre. with Pre.", "Pal. with Pal.",
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
  
  # get fill colors
  col_spec <- brewer.pal(11, "RdBu")[c(3,6,9)]
  if (show_ci == TRUE) {
    fill_col <- c()
    for (i in seq_len(ncol(boot_data))) {
      if (median(boot_data[, i]) > ci_perm[i, 3]) {
        fill_col <- c(fill_col, col_spec[1])
      } else if (median(boot_data[, i]) < ci_perm[i, 2]) {
        fill_col <- c(fill_col, col_spec[3])
      } else {
        fill_col <- c(fill_col, col_spec[2])
      }
    }
  } else {
    fill_col <- replicate(6, col_spec[2])
  }
  
  # combine boot strap violin plot with permutation CI
  violin <- ggplot(melted_data, aes(x = pair, y = prob)) +
    geom_violin(aes(color = pair, fill = pair), size = 1, trim = TRUE) +
    scale_color_manual(values = replicate(6, brewer.pal(9, "Greys")[8]),
                       guide = "none") +
    scale_fill_manual(values = fill_col, guide = "none") +
    geom_errorbar(mapping = aes(x = group, ymin = lower, ymax = upper),
                  data = ci_perm, width = 0.6, size = 1.5, 
                  alpha = ifelse(show_ci, 1, 0),
                  color = brewer.pal(9, "Greys")[5], inherit.aes = FALSE) +
    scale_x_discrete(labels = custom_labels) +
    stat_summary(data = melted_data, aes(x = pair, y = prob), 
                 fun = median, geom = "point", 
                 fill = brewer.pal(9, "Greys")[8], pch = 23, size = 5,
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
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank()
    )

  # save image to svg file
  ggsave(filename = paste0(plot_dir, "/", file_name, ".svg"),
         plot = violin,
         height = 10,
         width = 20)
  
  return(violin)
}
