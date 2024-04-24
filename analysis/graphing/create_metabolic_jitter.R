###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   create_metabolic_jitter.R
###############################################################################
library(ggplot2)
library(svglite)
library(reshape2)


# create a jitter plot with voilin of metabolic genes
create_metabolic_jitter <- function(data, classes, file_name, plot_dir) {
  
  classes = c("Oxidoreductases", "Transferases", "Hydrolases", "Lyases",
              "Isomerases", "Ligases", "Translocases")
  
  cat_number <- data.frame(
    name = c("ind", "pre", "pal"),
    cat = c(3, 2, 1)
  )
  
  melted_data <- as.data.frame(reshape2::melt(data))
  melted_data[,1] <- substr(melted_data[,1], 1, 3)
  colnames(melted_data) <- c("cat_name", "ec", "value")
  melted_data$cat_name <- as.character(melted_data$cat_name)
  melted_data$cat_name <- substr(melted_data$cat_name, 0, 3)
  
  melted_data <- merge(melted_data, cat_number,
                       by.x = "cat_name", by.y = "name"
                       )
  
  melted_data$cat <- factor(melted_data$cat)
  melted_data$ec <- as.character(melted_data$ec)
  melted_data$ec <- substr(melted_data$ec, 0, 1)
  melted_data$ec <- factor(melted_data$ec)
    
  star_height = max(melted_data$value)
  jitter <- ggplot(melted_data, aes(x = ec, y = value)) +
    geom_point(aes(fill = cat), color = "black", pch = 21, size = 4,
               position = position_jitterdodge(jitter.width = 0.55,
                                               dodge.width = 0.85)) +
    geom_violin(aes(color = cat), fill = "white") +
    # geom_boxplot(outlier.shape = NA, aes(color = cat), fill = "white") +
    scale_fill_manual(labels = c("Paleosample", "Pre-Industrial", "Industrial"),
                      values = rev(brewer.pal(9, "Greys")[c(3,5,8)])) +
    labs(fill = "Categories", y = "Scaled log(CPM + 1)",
         x = "Enzyme Class",
         title = "Enzyme Classes of Most Differentially Represented Genes") +
    scale_x_discrete(labels = classes) +
    theme_bw() +
    theme(
      plot.margin = margin(20, 20, 20, 20, "points"),
      axis.title.y = element_text(size = 18,
                                  face = "bold",
                                  margin = margin(t = 0, r = 20, b = 0, l = 0)),
      axis.title.x = element_blank(), 
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
