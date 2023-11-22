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
origin_labels <- c("ind.DNK" = "Denmark (n = 109)",
                   "ind.ESP" = "Spain (n = 140)",
                   "ind.USA" = "USA (n = 169)",
                   "pre.FJI" = "Fiji (n = 174)",
                   "pre.MDG" = "Madagascar (n = 112)",
                   "pre.MEX" = "Mexico (n = 22)",
                   "pre.PER" = "Peru (n = 36)",
                   "pre.TZA" = "Tanzania (n = 27)",
                   "pal.AWC" = "AWC (USA) (n = 3)",
                   "pal.BEL" = "Beligum (n = 1)",
                   "pal.BMS" = "BMS (USA) (n = 2)",
                   "pal.ENG" = "England (n = 1)",
                   "pal.ZAF" = "South Africa (n = 3)",
                   "pal.ZAP" = "Zape (MEX) (n = 3)")

# labels for heatmap and barplots
ind_label <- c("ind.DNK", "ind.ESP", "ind.USA")
pre_labels <- c("pre.FJI", "pre.MDG", "pre.MEX", "pre.PER", "pre.TZA")
pal_labels <- c("pal.AWC", "pal.BEL", "pal.BMS", "pal.ENG", "pal.ZAF", "pal.ZAP")
cat_labels <- c(ind_label, pre_labels, pal_labels)

# reference for pair labels based on category names
pair_labels <- c("Ind. with Ind.", "Pre. with Pre.", "Pal. with Pal.",
                 "Ind. with Pal", "Ind. with Pre", "Pre. with Pal.")
