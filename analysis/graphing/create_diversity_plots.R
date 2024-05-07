###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   create_diversity_plots.R
###############################################################################
library(ggplot2)


# generate a shannon diversity index plot
create_diversity_plots <- function(data, div_index, file_name, plot_dir) {
  
  plot_title <- paste0(div_index, " Diversity Index")
  plot_y_lab <- paste0(div_index, " Index")
  data$Group <- factor(data$Group, levels = c("pal", "pre", "ind"))
  
  diversity_plot <- ggplot(data, aes(x = Group, y = diversity_index)) +
    geom_point(aes(fill = Group), color = "black", pch = 21, size = 4, 
               position = position_jitterdodge(jitter.width = 0.55,
                                               dodge.width = 0.85)) +
    # geom_violin(aes(color = Group), fill = "white") +
    # geom_boxplot(outlier.shape = NA, aes(color = Group), fill = "white") +
    labs(title = plot_title, x = "Group", y = plot_y_lab) +
    # scale_y_continuous(limits = c(6, 7)) +
    theme_minimal()
  
  # save image to svg file
  file_name <- append_time_to_filename(file_name)
  ggsave(filename = paste0(plot_dir, "/", file_name, ".svg"),
         plot = diversity_plot,
         height = 8,
         width = 14)
  
  return(diversity_plot)
}
