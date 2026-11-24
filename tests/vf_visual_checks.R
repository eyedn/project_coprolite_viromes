###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   vf_visual_checks.R
###############################################################################

# rebuild final-size previews from the exported plotted counts
suppressPackageStartupMessages(library(tidyverse))
source("analysis/misc/prepare_checkv_vf_categories.R")
source("analysis/graphing/create_vf_composition.R")
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1L)
root <- normalizePath(args[1], mustWork = TRUE)
directory <- file.path(root, "contigs", "figures", "VFDB_setA")
reference <- read.csv(paste0(
  "../project_coprolite_viromes_NOT_CODE/data/20261019/VFs.csv"
))
colnames(reference) <- reference[1, ]
reference <- reference[-1, ]
empty <- tibble(checkv.filter = character(), genome.id = character(),
                feature_id = character(), vf.id = character(),
                annotation = character())
palette <- prepare.checkv.vf.categories(empty, reference)$palette
origin.order <- c("AUT", "AWC", "BMS", "ZAF", "ZAP", "FJI", "MDG", "MEX",
                   "NPL", "PER", "TZA", "CHN", "DNK", "ESP", "USA")
files <- list.files(directory, "^contig_vf_composition_.*_counts.csv$",
                     full.names = TRUE)
stopifnot(length(files) == 8L)
for (path in files) {
  data <- read.csv(path)
  separate <- grepl("_lifestyle", unique(data$layout))
  countries <- grepl("^origin_", unique(data$layout))
  order <- if (countries) {
    c(origin.order, sort(setdiff(unique(data$group), origin.order)))
  } else c("pal", "pre", "ind")
  categories <- if (unique(data$mapping) == "mapped_only") {
    setdiff(names(palette), "Unmapped VF category")
  } else names(palette)
  data <- data %>% mutate(
    group = factor(group, order),
    lifestyle = factor(lifestyle,
      if (separate) c("Lytic", "Temperate") else "All"),
    vf.category = factor(vf.category, categories)
  )
  plot <- create.vf.composition(data, palette, separate)
  ggplot_build(plot)
  stem <- sub("_counts.csv$", "", basename(path))
  ggsave(file.path(root, paste0(stem, "_preview.png")), plot,
           device = ragg::agg_png, width = if (countries) 17 else 11,
           height = 8, dpi = 90)
}
cat("PASS: eight final-size plot previews rebuilt from exported counts\n")
