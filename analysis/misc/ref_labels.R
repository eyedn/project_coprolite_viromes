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
origin_labels <- c("ind.CHN" = "China",
                   "ind.DNK" = "Denmark",
                   "ind.ESP" = "Spain",
                   "ind.USA" = "USA",
                   "pre.FJI" = "Fiji",
                   "pre.MDG" = "Madagascar",
                   "pre.MEX" = "Mexico",
                   "pre.NPL" = "Nepal",
                   "pre.PER" = "Peru",
                   "pre.TZA" = "Tanzania",
                   "pal.AUT" = "Austria",
                   "pal.AWC" = "AWC (USA)",
                   "pal.BEL" = "Beligum",
                   "pal.BMS" = "BMS (USA)",
                   "pal.ENG" = "England",
                   "pal.ZAF" = "South Africa",
                   "pal.ZAP" = "Zape (MEX)")

# labels for heatmap and barplots
ind_label <- c("ind.CHN", "ind.DNK", "ind.ESP", "ind.USA")
pre_labels <- c("pre.FJI", "pre.MDG", "pre.MEX", "pre.NPL", "pre.PER", "pre.TZA")
pal_labels <- c("pal.AUT", "pal.AWC", "pal.BEL", "pal.BMS", "pal.ENG", "pal.ZAF", "pal.ZAP")
cat_labels <- c(ind_label, pre_labels, pal_labels)

# reference for pair labels based on category names
pair_labels <- c("Ind. with Ind.", "Pre. with Pre.", "Pal. with Pal.",
                 "Ind. with Pal.", "Ind. with Pre.", "Pre. with Pal.")
