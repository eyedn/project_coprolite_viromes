###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   test_checkv_r_contracts.R
###############################################################################
library(tidyverse)

report.path <- file.path("analysis", "analysis_checkvhits.Rmd")
report.text <- paste(readLines(report.path, warn = FALSE), collapse = "\n")

required.patterns <- c(
  "selected.genome.id",
  "selected.annotation",
  "checkv_genome_metadata.csv",
  "checkv_genome_features.csv",
  "checkv_genome_vf_stats.csv",
  "Original CheckV analysis",
  "Complete CheckV genome analysis",
  "geom_segment",
  "facet_wrap"
)

for (pattern in required.patterns) {
  stopifnot(grepl(pattern, report.text, fixed = TRUE))
}

source(file.path("analysis", "misc", "prepare_checkv_feature_map.R"))
source(file.path("analysis", "misc", "normalize_checkv_lifestyle.R"))

stopifnot(
  identical(
    normalize.checkv.lifestyle(c("Virulent", "Lytic", "Temperate")),
    c("lytic", "lytic", "temperate")
  )
)

features <- data.frame(
  checkv.filter = c("conservative", "aggressive", "conservative"),
  genome.id = c("g1", "g1", "g1"),
  annotation = c("bacterial", "viral", "vf"),
  feature.id = c("b1", "v1", "b1"),
  start = c(1, 10, 1),
  end = c(5, 15, 5),
  strand = c("+", "-", "+"),
  product = c("enzyme", "capsid", "enzyme"),
  ec.number = c("1.2.3.4", "2.3.4.5", "1.2.3.4"),
  vf.id = c(NA, NA, "VF1"),
  full.seq.score = c(NA, NA, 50)
)

for (annotation in c("viral", "bacterial", "vf")) {
  selected <- prepare.checkv.feature.map(features, "g1", annotation)
  stopifnot(all(selected$annotation == annotation))
  stopifnot(all(selected$y != 0))
}

invalid <- features
invalid$ec.number[1] <- NA
stopifnot(nrow(prepare.checkv.feature.map(invalid, "g1", "bacterial")) == 0)

invalid <- features
invalid$product[1] <- "hypothetical protein"
stopifnot(nrow(prepare.checkv.feature.map(invalid, "g1", "bacterial")) == 0)
