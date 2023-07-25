###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   create_jitter.R
###############################################################################
library(ggplot2)
library(svglite)
library(reshape2)


# create a beeswarms plot of paired-cluserting tendencies
create_jitter <- function(data, file_name, plot_dir) {
  ec_classes <- c("Oxidoreductases", "Transferases", "Hydrolases", "Lyases",
                  "Isomerases", "Ligases", "Translocases")
  
  melted_data <- as.data.frame(melt(data))
  colnames(melted_data) <- c("cat", "ec", "value")
  
  melted_data$cat <- as.character(melted_data$cat)
  melted_data$cat <- substr(melted_data$cat, 0, 3)
  for (i in seq_len(nrow(melted_data))) {
    ifelse(melted_data[i, "cat"] == "ind", melted_data[i, "cat"] <- 1,
           ifelse(melted_data[i, "cat"] == "pre", melted_data[i, "cat"] <- 2,
                  melted_data[i, "cat"] <- 3))
  }
  melted_data$cat <- factor(melted_data$cat)
  
  melted_data$ec <- as.character(melted_data$ec)
  melted_data$ec <- substr(melted_data$ec, 0, 1)
  melted_data$ec <- factor(melted_data$ec)
    
  jitter <- ggplot(melted_data, aes(x = ec, y = value, fill = cat)) +
    geom_point(color = "black", pch = 21, size = 4, 
               position = position_jitterdodge(jitter.width = 0.55,
                                               dodge.width = 0.85)) +
    scale_fill_manual(labels = c("Industrial", "Pre-Industrial", "Paleosample"),
                      values = brewer.pal(9, "Greys")[c(3,5,8)]) +
    labs(fill = "Categories", y = "Scaled log(CPM + 1)",
         x = "Enzyme Class",
         title = "Representation of Enzyme Classes Across Sample Categories") +
    scale_x_discrete(labels = ec_classes) +
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
      axis.text = element_text(size = 18),
      axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1),
      legend.position = "top",
      legend.title = element_blank(),
      legend.text = element_text(size = 14)
    )
  
  # save image to svg file
  ggsave(filename = paste0(plot_dir, "/", file_name, ".svg"),
         plot = jitter,
         height = 10,
         width = 18)
  
  return(jitter)
}
