###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   create_row_legend.R
###############################################################################
library(grid)
library(gridSVG)
library(RColorBrewer)


# Function to draw the legend
create_row_legend <- function(color_set, filename) {
  num_colors <- length(color_set)
  
  # Start the svg device
  svg(filename, width=4, height=4)  # Set the appropriate height for spacing
  
  # Create a grid layout
  grid.newpage()
  pushViewport(viewport(layout = grid.layout(nrow = num_colors + 1, ncol = 3)))
  
  # Define margins for spacing between boxes
  margin_height <- unit(5, "mm")
  
  # Draw the squares with colors and add text labels
  for (i in 1:num_colors) {
    # Calculate the position for the box, leave space at the top
    box_top <- unit(i, "lines") - margin_height
    box_bottom <- unit(i - 1, "lines") + margin_height
    
    # Draw the colored box with black outline
    grid.rect(gp=gpar(fill=color_set[i], col="black", lwd = 4), 
              vp=viewport(layout.pos.row=i+1, layout.pos.col=2),
              y=unit(0.5, "npc") + box_bottom,
              height=unit(1, "npc") - margin_height)
  }
  
  # Turn off the device
  dev.off()
}
