###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   create_samples_map.R
###############################################################################
library(ggplot2)
library(svglite)
library(maps)


# return a map with coutries where samples come from filled in with a color
create_samples_map <- function(cat) {
  # print map of samples
  thismap <- map_data("world")
  
  # determine colors based off category
  if (cat == "ind") {
    thismap$fill <- ifelse(thismap$region %in% c("Spain",
                                                 "Denmark",
                                                 "USA"),
                           safe_colors[1], "white")
  } else if (cat == "pre") {
    thismap$fill <- ifelse(thismap$region %in% c("Fiji",
                                                 "Madagascar",
                                                 "Tanzania",
                                                 "Peru",
                                                 "Mexico"),
                                  safe_colors[2], "white")
  } else if (cat == "pal") {
    thismap$fill <- ifelse(thismap$region %in% c("Belgium",
                                                 "UK",
                                                 "South Africa",
                                                 "Mexico",
                                                 "USA"),
                                         safe_colors[3], "white")
  }

  samples <- ggplot(thismap, aes(long, lat, fill = fill, group = group)) +
    geom_polygon(colour = "gray") +
    ggtitle("Map of Samples") +
    scale_fill_identity() +
    theme_void() +
    coord_equal() +
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
