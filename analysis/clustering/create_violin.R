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
                linewidth = 1.5, trim = TRUE) +
    scale_fill_manual(values = replicate(3, brewer.pal(9, "Greys")[2]),
                      guide = "none") +
    annotate("segment", x = 1.15, xend = 1.15,
             y = ci[[1, "lower"]], yend = ci[[1, "upper"]],
             size = 2, color = brewer.pal(11, "RdBu")[2]) +
    annotate("segment", x = 2.5, xend = 2.5,
             y = ci[[2, "lower"]], yend = ci[[2, "upper"]], 
             size = 2, color = brewer.pal(11, "RdBu")[2]) +
    annotate("segment", x = 3.2, xend = 3.2,
             y = ci[[3, "lower"]], yend = ci[[3, "upper"]], 
             size = 2, color = brewer.pal(11, "RdBu")[2]) +
    annotate("text", label = "***", x = 1, 
             y = max(c(ci[4:6, "upper"], boot_data[, 1])) + 0.025,
             size = 12, color = brewer.pal(9, "Greys")[8]) +
    stat_summary(aes(x = pair, y = prob), fun = median, geom = "point", 
                 fill = brewer.pal(9, "Greys")[8],
                 pch = 23, size = 6, inherit.aes = FALSE) +
    scale_y_continuous(limits = c(0, 1.05),
                       breaks = c(0, 0.25, 0.5, 0.75, 1)) +
    theme_bw() +
    theme(
      plot.margin = margin(20, 5, 20, 20, "points"),
      axis.title.x = element_blank(),
      axis.title.y = element_blank(),
      axis.text.x = element_blank(),
      axis.text.y = element_text(size = 14, color = "black", face = "bold",
                                 hjust = -0.5),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      axis.ticks.x = element_blank(),
      axis.ticks.y = element_line(linewidth = 2, color = "black"),  
      panel.border = element_rect(color = "black", linewidth = 2, fill = NA)
    )
  

  # generate graph for heterogeneous pairs
  melted_hete <- melted_data[melted_data$pair > 3, , drop = FALSE]
  melted_hete$pair <- factor(melted_hete$pair)
  
  hete_violin <- ggplot(melted_hete, aes(y = prob)) +
    geom_violin(aes(x = pair, fill = pair), color = brewer.pal(9, "Greys")[8],
                linewidth = 1.5, trim = TRUE) +
    scale_fill_manual(values = replicate(3, brewer.pal(9, "Greys")[2]),
                      guide = "none") +
    annotate("segment", x = 1.1, xend = 1.1,
             y = ci[[4, "lower"]], yend = ci[[4, "upper"]],
             size = 2, color = brewer.pal(11, "RdBu")[2]) +
    annotate("segment", x = 2.25, xend = 2.25,
             y = ci[[5, "lower"]], yend = ci[[5, "upper"]], 
             size = 2, color = brewer.pal(11, "RdBu")[2]) +
    annotate("segment", x = 3.275, xend = 3.275,
             y = ci[[6, "lower"]], yend = ci[[6, "upper"]], 
             size = 2, color = brewer.pal(11, "RdBu")[2]) +
    annotate("text", x = 3.4, 
             y = (ci[[6, "lower"]] + ci[[6, "upper"]]) / 2,
             label = "Null Distribution", angle = '-90',
             size = 6, color = brewer.pal(11, "RdBu")[2]) +
    annotate("text", label = "****", x = 1, 
             y = max(c(ci[4:6, "upper"], boot_data[, 4])) + 0.025,
             size = 12, color = brewer.pal(9, "Greys")[8]) +
    stat_summary(aes(x = pair, y = prob), fun = median, geom = "point", 
                 fill = brewer.pal(9, "Greys")[8],
                 pch = 23, size = 6, inherit.aes = FALSE) +
    scale_y_continuous(limits = c(0, 1.05),
                       breaks = c(0, 0.25, 0.5, 0.75, 1)) +
    theme_bw() +
    theme(
      plot.margin = margin(20, 20, 20, 5, "points"),
      axis.title.x = element_blank(),
      axis.text.x = element_blank(),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      axis.ticks.x = element_blank(),
      title = element_blank(),
      axis.title.y.left = element_blank(),
      axis.text.y.left = element_blank(),
      axis.ticks.y = element_line(linewidth = 2, color = "black"),  
      panel.border = element_rect(color = "black", linewidth = 2, fill = NA)
    )
  
  
  violin <- homo_violin + hete_violin
  
  # save image to svg file
  file_name <- append_time_to_filename(file_name)
  ggsave(filename = paste0(plot_dir, "/", file_name, ".svg"),
         plot = violin,
         height = 7,
         width = 14)
  
  return(violin)
}
