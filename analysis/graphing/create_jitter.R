###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   create_jitter.R
###############################################################################
library(ggplot2)
library(svglite)
library(reshape2)


# create a beeswarms plot of paired-cluserting tendencies
create_jitter <- function(data, classes, file_name, plot_dir) {
  
  melted_data <- as.data.frame(melt(data))
  colnames(melted_data) <- c("cat", "ec", "value")
  
  melted_data$cat <- as.character(melted_data$cat)
  melted_data$cat <- substr(melted_data$cat, 0, 3)
  for (i in seq_len(nrow(melted_data))) {
    ifelse(melted_data[i, "cat"] == "ind", melted_data[i, "cat"] <- 3,
           ifelse(melted_data[i, "cat"] == "pre", melted_data[i, "cat"] <- 2,
                  melted_data[i, "cat"] <- 1))
  }
  melted_data$cat <- factor(melted_data$cat)
  
  melted_data$ec <- as.character(melted_data$ec)
  melted_data$ec <- substr(melted_data$ec, 0, 1)
  melted_data$ec <- factor(melted_data$ec)
    
  star_height = max(melted_data$value)
  jitter <- ggplot(melted_data, aes(x = ec, y = value, fill = cat)) +
    geom_point(color = "black", pch = 21, size = 4, 
               position = position_jitterdodge(jitter.width = 0.55,
                                               dodge.width = 0.85)) +
    scale_fill_manual(labels = c("Paleosample", "Pre-Industrial", "Industrial"),
                      values = rev(brewer.pal(9, "Greys")[c(3,5,8)])) +
    # annotate("text", label = "**", x = 1, y = star_height + 1,
    #          size = 12, color = brewer.pal(11, "RdBu")[8]) +
    # annotate("text", label = "**", x = 1, y = star_height + 3,
    #          size = 12, color = brewer.pal(11, "RdBu")[3]) +
    # # annotate("text", label = "**", x = 2, y = star_height + 1,
    # #          size = 12, color = brewer.pal(11, "RdBu")[8]) +
    # annotate("text", label = "**", x = 2, y = star_height + 3,
    #          size = 12, color = brewer.pal(11, "RdBu")[3]) +
    # annotate("text", label = "**", x = 3, y = star_height + 1,
    #          size = 12, color = brewer.pal(11, "RdBu")[8]) +
    # annotate("text", label = "**", x = 3, y = star_height + 3,
    #          size = 12, color = brewer.pal(11, "RdBu")[3]) +
    # annotate("text", label = "**", x = 4, y = star_height + 1,
    #          size = 12, color = brewer.pal(11, "RdBu")[8]) +
    # annotate("text", label = "**", x = 4, y = star_height + 3,
    #          size = 12, color = brewer.pal(11, "RdBu")[3]) +
    # annotate("text", label = "**", x = 5, y = star_height + 1,
    #          size = 12, color = brewer.pal(11, "RdBu")[8]) +
    # # annotate("text", label = "**", x = 5, y = star_height + 3,
    # #          size = 12, color = brewer.pal(11, "RdBu")[3]) +
    # annotate("text", label = "**", x = 6, y = star_height + 1,
    #          size = 12, color = brewer.pal(11, "RdBu")[8]) +
    # annotate("text", label = "**", x = 6, y = star_height + 3,
    #          size = 12, color = brewer.pal(11, "RdBu")[3]) +
    # annotate("text", label = "**", x = 7, y = star_height + 1,
    #          size = 12, color = brewer.pal(11, "RdBu")[8]) +
    # annotate("text", label = "**", x = 7, y = star_height + 3,
    #          size = 12, color = brewer.pal(11, "RdBu")[3]) +
    labs(fill = "Categories", y = "Scaled log(CPM + 1)",
         x = "Enzyme Class",
         title = "Enzyme Classes of Most Differentially Represented Genes") +
    scale_x_discrete(labels = classes) +
    theme_bw() +
    theme(
      plot.margin = margin(20, 20, 20, 20, "points"),
      plot.title = element_text(size = 24,
                                face = "bold",
                                margin = margin(t = 0, r = 0, b = 20, l = 0)),
      axis.title.x = element_text(size = 18,
                                  face = "bold",
                                  margin = margin(t = 20, r = 0, b = 0, l = 0)),
      axis.title.y = element_text(size = 18,
                                  face = "bold",
                                  margin = margin(t = 0, r = 20, b = 0, l = 0)),
      axis.text = element_text(size = 14),
      legend.position = "top",
      legend.title = element_blank(),
      legend.text = element_text(size = 18),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      axis.ticks.x = element_blank()
    )
  
  # save image to svg file
  file_name <- append_time_to_filename(file_name)
  ggsave(filename = paste0(plot_dir, "/", file_name, ".svg"),
         plot = jitter,
         height = 8,
         width = 14)
  
  return(jitter)
}
