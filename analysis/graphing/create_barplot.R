###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   create_barplot.R
###############################################################################
library(ggplot2)
library(svglite)
library(RColorBrewer)


# create bar plot to show representation of * in terms of groups
create_barplot <- function(counts, plot_title, fill_pal, 
                           file_name, plot_dir) {
  melted_counts <- melt(counts)
  colnames(melted_counts) <- c("val", "group", "prop")
  melted_counts$val <- as.factor(melted_counts$val)
  
  bar <- ggplot(melted_counts, aes(x = val, y = prop, fill = group)) +
    geom_bar(stat = "identity", position = position_dodge()) +
    scale_fill_brewer(palette = fill_pal) +
    labs(x = "Sample Categories",
         y = "Median CPM",
         title = plot_title) +
    theme_bw() +
    theme(panel.grid.major = element_blank(),
          panel.grid.minor = element_blank())
  
  # save image to svg file
  ggsave(filename = paste0(plot_dir, "/", file_name, ".svg"),
         plot = bar,
         height = 5,
         width = 30)
  
  return(bar)
}
