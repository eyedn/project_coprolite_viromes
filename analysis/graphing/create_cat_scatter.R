###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   create_cat_scatter.R
###############################################################################
library(ggplot2)
library(reshape2)
library(RColorBrewer)
library(dplyr)
library(svglite)


# generate scatter plot
create_cat_scatter <- function(data, file_name, plot_dir) {

  colnames(data) <- c("value", "cat")
  
  violin <- ggplot(data = data, aes(x = cat)) +
    geom_point(aes(x = cat, fill = factor(cat), y = value),
               color = brewer.pal(9, "Greys")[8], size = 5,
               position = position_jitterdodge(dodge.width=0.9)) +
    scale_fill_manual(values = replicate(3, brewer.pal(9, "Greys")[8]),
                      guide = "none") +
    scale_color_manual(values = replicate(3, brewer.pal(9, "Greys")[2]),
                       guide = "none") +
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
