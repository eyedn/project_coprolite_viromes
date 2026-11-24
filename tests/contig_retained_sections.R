###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   contig_retained_sections.R
###############################################################################

# execute retained downstream chunks on a full render's real count matrix
suppressPackageStartupMessages(library(tidyverse))
source("analysis/stats/normalize_data.R")
source("analysis/stats/get_diff_repres_cols.R")
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 2L)
input.dir <- normalizePath(args[1], mustWork = TRUE)
dir.create(args[2], recursive = TRUE, showWarnings = FALSE)
figs.dir <- normalizePath(args[2], mustWork = TRUE)
version.figs.dir <- file.path(figs.dir, "VFDB_setA")
dir.create(version.figs.dir, showWarnings = FALSE)
data.dir <- normalizePath(paste0(
  "../project_coprolite_viromes_NOT_CODE/data/20261019"
))
SUBSET.TOP <- 100L
vf.counts <- read.csv(file.path(input.dir, "vf_counts.csv"),
                       row.names = 1, check.names = FALSE)
vf.meta.data <- read.csv(file.path(data.dir, "VFs.csv"))
vf.reference <- vf.meta.data
colnames(vf.reference) <- vf.reference[1, ]
vf.reference <- vf.reference[-1, c("VFID", "VFCID", "VF_Name", "VFcategory")]
report <- readLines("analysis/analysis_contigs.Rmd")
config.start <- which(startsWith(report, "EXCLUDED.ORIGINS <-"))
config.end <- config.start +
  which(report[config.start:length(report)] == ")")[1] - 1L
eval(parse(text = report[config.start:config.end]))
pdf(NULL)
for (label in c("gene-vf-differential", "plot-source-tracker-results",
                 "plot-mixing-proportions-from-sourcetracker")) {
  start <- which(startsWith(report, paste0("```{r ", label))) + 1L
  end <- start + which(report[start:length(report)] == "```")[1] - 2L
  eval(parse(text = report[start:end]))
}
dev.off()
cat("PASS: retained gene differential and complete SourceTracker chunks\n")
