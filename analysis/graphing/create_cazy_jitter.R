###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   create_cazy_jitter.R
###############################################################################
library(ggplot2)
library(svglite)
library(reshape2)
library(data.table)


# create a jitter plot with violin of virulence factors
create_cazy_jitter <- function(data, file_name, plot_dir) {
  
  # label data origin by category
  cat_number <- data.frame(
    name = c("ind", "pre", "pal"),
    cat = c(3, 2, 1)
  )
  
  melted_data <- reshape2::melt(data)
  melted_data[,1] <- substr(melted_data[,1], 1, 3)
  colnames(melted_data) <- c("cat_name", "cazy", "value")
  melted_data$cat_name <- substr(melted_data$cat_name, 0, 3)
  melted_data$cazy <- substr(melted_data$cazy, 0, 2)
  
  melted_data <- merge(melted_data, cat_number,
                       by.x = "cat_name", by.y = "name"
  )
  
  melted_data$cat <- factor(melted_data$cat)

  # create custom numbering for cazy category
  classes = c("Glycoside Hydrolase", "Glycosyltransferase",
              "Polysaccharise Lyase", "Carbohydrate Esterase",
              "Auxiliary Activies", "Carbohydrate-binding Module", "Other")
  
  cazy_cat <- data.frame(
    cazy = c("GH", "GT", "PL", "CE", "AA", "CB", "co", "do", "SL"),
    id = c(1, 2, 3, 4, 5, 6, 7, 7, 7)
  )
  
  # use data.table to perform merge
  melted_data <- as.data.table(melted_data)
  cazy_cat <- as.data.table(cazy_cat)
  melted_data <- melted_data[cazy_cat, on = .(cazy), nomatch = 0]
  melted_data <- as.data.frame(melted_data)
  
  # create plot
  star_height = max(melted_data$value)
  jitter <- ggplot(melted_data, aes(x = id, y = value)) +
    geom_point(aes(fill = cat), color = "black", pch = 21, size = 4,
               position = position_jitterdodge(jitter.width = 0.55,
                                               dodge.width = 0.85)) +
    # geom_violin(aes(color = cat), fill = "white") +
    geom_boxplot(outlier.shape = NA, aes(color = cat), fill = "white") +
    scale_fill_manual(labels = c("Paleosample", "Pre-Industrial", "Industrial"),
                      values = rev(brewer.pal(9, "Greys")[c(3,5,8)])) +
    labs(fill = "Categories", y = "Scaled log(CPM + 1)") +
    scale_x_discrete(labels = classes) +
    theme_bw() +
    theme(
      plot.margin = margin(20, 30, 30, 20, "points"),
      axis.title.y = element_text(size = 18,
                                  face = "bold",
                                  margin = margin(t = 0, r = 20, b = 0, l = 0)),
      axis.title.x = element_blank(), 
      axis.text.x = element_text(angle = -30, hjust = 0),
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
