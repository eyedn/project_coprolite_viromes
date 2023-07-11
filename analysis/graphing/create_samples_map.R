###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   create_samples_map.R
###############################################################################
library(ggplot2)
library(svglite)
library(maps)


# return a map with coutries where samples come from filled in with a color
create_samples_map <- function() {
  # print map of samples:
  thismap <- map_data("world")
  # Set colors
  thismap$fill <- ifelse(thismap$region %in% c("Spain",
                                               "Denmark"),
                        safe_colors[1],
                  ifelse(thismap$region %in% c("Fiji",
                                               "Madagascar",
                                               "Tanzania"),
                        safe_colors[2],
                  ifelse(thismap$region %in% c("Belgium",
                                               "England",
                                               "South Africa",
                                               "Italy"),
                        safe_colors[3],
                  ifelse(thismap$region %in% c("USA"),
                        safe_colors[4],
                  ifelse(thismap$region %in% c("Mexico",
                                               "Peru"),
                        safe_colors[6],
                  "white")))))

  # Use scale_fill_manual to set correct colors
  samples <- ggplot(thismap, aes(long, lat, fill = fill, group = group)) +
    geom_polygon(colour = "gray") +
    ggtitle("Map of Samples") +
    scale_fill_identity() +
    theme_bw() +
    theme(
      plot.margin = margin(20, 20, 20, 20, "points"),
      plot.title = element_text(size = 20,
                                face = "bold", 
                                margin = margin(t = 0, r = 0, b = 20, l = 0)),
      axis.title.x = element_blank(),
      axis.title.y = element_blank(),
      axis.text = element_blank(),
      legend.position = "top",
      legend.title = element_text(size = 14),
      legend.text = element_text(size = 12)
    )
  return(samples)
}
