###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   ref_labels.R
###############################################################################


# label sample categories for facet graph
sample_labels <- c("ind" = "Modern, Industrial",
                   "pal" = "Paleo-sample",
                   "pre" = "Modern, Pre-Industrial")

# label sample categories for facet graph
origin_labels <- c("ind.DNK" = "Denmark",
                   "ind.ESP" = "Spain",
                   "ind.USA" = "USA",
                   "pre.FJI" = "Fiji",
                   "pre.MDG" = "Madagascar",
                   "pre.MEX" = "Mexico",
                   "pre.PER" = "Peru",
                   "pre.TZA" = "Tanzania",
                   "pal.AWC" = "AWC (USA)",
                   "pal.BEL" = "Beligum",
                   "pal.BMS" = "BMS (US)",
                   "pal.ENG" = "England",
                   "pal.ZAF" = "South Africa",
                   "pal.ZAP" = "Zape (MEX)")

# reference for pair labels based on category names
pair_labels <- c("Ind. vs. Ind.", "Pre. vs. Pre.", "Pal. vs. Pal.",
                 "Ind. vs. Pal", "Ind. vs. Pre", "Pre. vs. Pal.")
