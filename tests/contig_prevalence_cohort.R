###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   contig_prevalence_cohort.R
###############################################################################

suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(progress))
source("analysis/stats/get_row_median.R")
report <- readLines("analysis/analysis_contigs.Rmd")

# execute the report's real preparation and all three bootstrap calls
check.cohort <- function(lifestyle, stats) {
  fixture.dir <- tempfile(tmpdir = "tests")
  dir.create(fixture.dir)
  on.exit(unlink(fixture.dir, recursive = TRUE), add = TRUE)
  write.csv(lifestyle, file.path(fixture.dir, "lifestyle_counts.csv"))
  env <- new.env()
  env$data.dir <- fixture.dir
  env$MIN_TOTAL_ORFS <- 5L
  env$MAX.ITER <- 1000L
  start <- which(startsWith(report, "EXCLUDED.ORIGINS <-"))
  end <- start + which(report[start:length(report)] == ")")[1] - 1L
  eval(parse(text = report[start:end]), env)
  start <- which(startsWith(report, "lifestyle.counts <- read.csv("))
  end <- which(startsWith(report, "# bootstrap group and country medians")) - 1L
  eval(parse(text = report[start:end]), env)
  env$sample.vf.stats <- stats
  start <- which(startsWith(report, "# use pooled sample totals for prevalence"))
  end <- start + which(report[start:length(report)] == "```")[1] - 2L
  eval(parse(text = report[start:end]), env)
  start <- which(startsWith(report, "lifestyle.vf.plot.data <-"))
  end <- which(startsWith(report, "lifestyle.vf.plot <- ggplot(")) - 1L
  env$version.figs.dir <- fixture.dir
  eval(parse(text = report[start:end]), env)
  calls <- list()
  env$get_row_median <- function(data, num_iter, row_num, cats, ...) {
    calls[[length(calls) + 1L]] <<- list(
      samples = names(data), values = as.numeric(data[row_num, ])
    )
    get_row_median(data, num_iter, row_num, cats, ...)
  }
  start <- which(startsWith(report,
    "```{r sample-vf-prevalence-bootstrap,")) + 1L
  end <- which(startsWith(report,
    "# produce group, country, and balanced-group prevalence violin plots")) - 1L
  eval(parse(text = report[start:end]), env)
  stopifnot(length(calls) == 3L)
  for (call in calls) {
    stopifnot(identical(call$samples, env$lifestyle.vf.plot.data$sample),
              identical(call$values,
                        env$lifestyle.vf.plot.data$vf_orf_prevalence))
  }
  stopifnot(env$pal.size.vf.prot ==
              sum(env$lifestyle.vf.plot.data$group == "pal"),
            !any(grepl("\\.(BEL|ENG)_", calls[[1]]$samples)))
  env
}
ids <- c("pal.ZAF_keep", "pal.ZAF_low", "pre.FJI_keep", "ind.USA_keep",
          "pal.BEL_removed", "pal.ENG_removed", "pal.AUT_2612",
          "pre.FJI_infinite", "pal.ZAP_five_orfs", "pre.FJI_zero_hits")
lifestyle <- as.data.frame(matrix(0L, nrow = 3L, ncol = length(ids)))
names(lifestyle) <- ids
rownames(lifestyle) <- c("temperate", "virulent", "unpredicted")
lifestyle["temperate", ] <- 100L
lifestyle["virulent", ] <- 100L
lifestyle[, "pal.ZAF_low"] <- c(3L, 2L, 0L)
lifestyle[, "pre.FJI_infinite"] <- c(200L, 0L, 0L)
stats <- tibble(sample = ids,
                 total_bacterial_orfs = if_else(
                   ids == "pal.ZAP_five_orfs", 5L, 10L),
                 qualifying_vf_orfs = if_else(
                   ids == "pre.FJI_zero_hits", 0L, 1L)) %>%
  mutate(vf_orf_prevalence = qualifying_vf_orfs / total_bacterial_orfs)
res <- check.cohort(lifestyle, stats)
stopifnot(setequal(res$lifestyle.vf.plot.data$sample,
  c("pal.ZAF_keep", "pre.FJI_keep", "ind.USA_keep", "pre.FJI_zero_hits")))
# excluded columns may already have been removed from the source dataset
keep <- !grepl("\\.(BEL|ENG)_", ids) & ids != "pal.AUT_2612"
invisible(check.cohort(lifestyle[, keep, drop = FALSE], stats[keep, ]))
cat("PASS: shared cohorts, finite ratios, cutoffs, zeros, and absent BEL/ENG\n")

# both reports create missing output directories and retain isolated overrides
check.outputs <- function(path) {
  lines <- readLines(path)
  start <- which(startsWith(lines, "figs.dir <- getOption("))
  end <- which(startsWith(lines, "dir.create(figs.dir,"))
  expressions <- parse(text = lines[start:end])
  default <- expressions[[1]][[3]][[3]]
  stopifnot(endsWith(default,
    "project_coprolite_viromes_NOT_CODE/outputs20261123"))
  fixture.dir <- tempfile(tmpdir = "tests")
  target <- file.path(fixture.dir, "nested", "figures")
  old.options <- options(coprolite.figs.dir = target)
  on.exit({
    options(old.options)
    unlink(fixture.dir, recursive = TRUE)
  }, add = TRUE)
  env <- new.env()
  eval(expressions, env)
  stopifnot(dir.exists(target), identical(env$figs.dir, target))
}
for (path in c("analysis/analysis_contigs.Rmd",
                "analysis/analysis_checkvhits.Rmd")) check.outputs(path)
cat("PASS: outputs20261123 defaults, directory creation, isolated overrides\n")
