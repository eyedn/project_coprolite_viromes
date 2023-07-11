###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   ref_visuals.R
###############################################################################
library(rcartocolor)


# generate safe colors from rcartocolor plus 4 more for all samples origins
safe_colors <- c(carto_pal(12, "Safe"),
                 "#E69F00", "#000000", "#b0f2bc", "#D55E00")

safe_shapes <- c(15, 16, 17, 18, 9, 10, 11, 12, 14)

