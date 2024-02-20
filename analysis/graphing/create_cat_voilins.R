###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   create_lifestyle_violin.R
###############################################################################
library(ggplot2)
library(reshape2)
library(RColorBrewer)
library(dplyr)
library(svglite)


# generate violin graph from temperate-to-virulent bootstrapping
create_cat_voilins <- function(data, ci_offset, file_name, plot_dir) {
  
  melted_data <- melt(data)
  colnames(melted_data) <- c("point", "cat", "value")
  melted_data$cat <- factor(melted_data$cat, levels = c("pal", "pre", "ind"))
  
  # calculate 95% CI for each category
  ci_data <- melted_data %>%
    group_by(cat) %>%
    summarise(mean_value = mean(value),
              ymin = quantile(value, 0.025),
              ymax = quantile(value, 0.975))
  
  violin <- ggplot(data = melted_data, aes(x = cat)) +
    geom_violin(aes(x = cat, fill = factor(cat), y = value), 
                color = brewer.pal(9, "Greys")[8],
                linewidth = 1.5, trim = TRUE, width = 1) +
    scale_fill_manual(values = replicate(3, brewer.pal(9, "Greys")[2]),
                      guide = "none") +
    stat_summary(aes(x = cat, y = value), fun = median, geom = "point", 
                 fill = brewer.pal(9, "Greys")[8],
                 color = brewer.pal(9, "Greys")[2],
                 stroke = 1, pch = 23, size = 5.5, inherit.aes = FALSE) +
    annotate("text", x = (1.1 + ci_offset[1]), 
             y = (ci_data[[1, "ymin"]] + ci_data[[1, "ymax"]]) / 2,
             label = "95% CI", angle = '-90',
             size = 8, color = brewer.pal(11, "RdBu")[10]) +
    annotate("segment", x = (1 + ci_offset[1]), xend = (1 + ci_offset[1]),
             y = ci_data[[1, "ymin"]], yend = ci_data[[1, "ymax"]],
             size = 2, color = brewer.pal(11, "RdBu")[10]) +
    annotate("segment", x = (2 + ci_offset[2]), xend = (2 + ci_offset[2]),
             y = ci_data[[2, "ymin"]], yend = ci_data[[2, "ymax"]], 
             size = 2, color = brewer.pal(11, "RdBu")[10]) +
    annotate("segment", x = (3 + ci_offset[3]), xend = (3 + ci_offset[3]),
             y = ci_data[[3, "ymin"]], yend = ci_data[[3, "ymax"]], 
             size = 2, color = brewer.pal(11, "RdBu")[10]) +
    theme_bw() +
    theme(
      plot.margin = margin(20, 5, 20, 20, "points"),
      axis.title.x = element_blank(),
      axis.title.y = element_blank(),
      # axis.text.x = element_blank(),
      axis.text.y = element_text(size = 14, color = "black",
                                 face = "bold", hjust = -0.5),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      axis.ticks.x = element_blank(),
      axis.ticks.y = element_line(linewidth = 2, color = "black"),  
      panel.border = element_rect(color = "black", size = 2, fill = NA)
    )
  
  # save image to svg file
  file_name <- append_time_to_filename(file_name)
  ggsave(filename = paste0(plot_dir, "/", file_name, ".svg"),
         plot = violin,
         height = 7,
         width = 7)
  
  return(violin)
}
