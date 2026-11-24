###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   render_vf_reports.R
###############################################################################

# render one report to an explicit root; optionally set its figure root
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) %in% c(2L, 3L))
report <- normalizePath(file.path("analysis", args[1]), mustWork = TRUE)
dir.create(args[2], recursive = TRUE, showWarnings = FALSE)
output <- normalizePath(args[2], mustWork = TRUE)
work <- file.path(output, "intermediates")
dir.create(work, showWarnings = FALSE)
figure.dir <- if (length(args) == 3L) args[3] else file.path(output, "figures")
dir.create(figure.dir, recursive = TRUE, showWarnings = FALSE)
options(coprolite.figs.dir = normalizePath(figure.dir, mustWork = TRUE))
knitr::opts_chunk$set(dev = "ragg_png", dpi = 90)
rmarkdown::render(
  report, output_dir = output, intermediates_dir = work,
  output_options = list(self_contained = FALSE),
  envir = new.env(parent = globalenv()), quiet = FALSE
)
