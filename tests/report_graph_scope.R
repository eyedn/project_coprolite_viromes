###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   report_graph_scope.R
###############################################################################

suppressPackageStartupMessages(library(tidyverse))
for (path in c(
  "misc/normalize_checkv_lifestyle.R", "misc/validate_vf_pool.R",
  "misc/prepare_checkv_vf_categories.R", "misc/prepare_checkv_vf_composition.R",
  "misc/prepare_checkv_analysis_pool.R", "misc/prepare_vf_composition.R",
  "misc/read_contig_vf_categories.R", "misc/export_vf_category_analysis.R",
  "stats/compare_sample_vf_categories.R", "stats/downsample_checkv_vf.R",
  "graphing/create_vf_composition.R"
)) source(file.path("analysis", path))

reference <- tibble(VFID = c("a", "b", "z"), VFCID = "class",
                    VF_Name = c("A", "B", "Z"),
                    VFcategory = c("Adhesion", "Toxin", "Absent"))
reference.names <- sort(unique(reference$VFcategory))
metadata <- tibble(
  checkv.filter = "conservative", genome.id = c("pal-AUT_x", "pal-BEL_x",
    "pal-ENG_x", "pre-FJI_x", "ind-USA_x"),
  category = c("pal", "pal", "pal", "pre", "ind"),
  origin = c("AUT", "BEL", "ENG", "FJI", "USA"), sample = "x",
  checkv.lifestyle = "Lytic", genome.length = 1000L
)
stats <- metadata %>% mutate(total.bacterial.orfs = 10L,
  qualifying.vf.orfs = 2L, vf.orf.prevalence = .2, vf_present = 1L)
features <- crossing(genome.id = metadata$genome.id, feature_id = c("1", "2")) %>%
  mutate(checkv.filter = "conservative", annotation = "vf",
         vf.id = if_else(feature_id == "1", "a", "unmapped"))
# a retained genome with only unmapped calls becomes mapped-VF absent
features$vf.id[features$genome.id == "pre-FJI_x"] <- "unmapped"
pool <- prepare.checkv.analysis.pool(stats, metadata, features, reference,
                                      excluded.origins = c("BEL", "ENG"))
stopifnot(nrow(pool$stats) == 3L, nrow(pool$metadata) == 3L,
          !any(pool$stats$origin %in% c("BEL", "ENG")),
          !any(grepl("BEL|ENG", pool$features$genome.id)),
          !"Unmapped VF category" %in% names(pool$palette),
          all(pool$vf$vf.category %in% reference.names),
          filter(pool$stats, origin == "FJI")$qualifying.vf.orfs == 0L,
          filter(pool$stats, origin == "FJI")$vf_present == 0L,
          sum(pool$stats$qualifying.vf.orfs) == nrow(pool$vf))

# the downsampling report retains mapped-only draws and fixed audit tables
small.stats <- crossing(category = c("pal", "pre", "ind"),
  checkv.lifestyle = c("lytic", "temperate"), index = 1:3) %>%
  mutate(genome.id = paste(category, checkv.lifestyle, index),
         checkv.filter = "conservative",
         qualifying.vf.orfs = as.integer(index == 1 &
                                          checkv.lifestyle == "lytic"))
vf <- small.stats %>% filter(qualifying.vf.orfs > 0) %>%
  transmute(checkv.filter, genome.id, feature_id = "1", vf.category = "Adhesion")
draws <- downsample.checkv.vf(small.stats, vf, reference.names,
  iterations = 100L, lytic = 2L, temperate = 1L,
  paleo.lytic = 3L, paleo.temperate = 3L, mapped.only = TRUE)
stopifnot(identical(unique(draws$iterations$mapping), "mapped_only"),
          all(draws$example$iteration == 1L),
          identical(draws$example,
                      filter(draws$iterations, iteration == 1L)))
# all variants share arithmetic means, fixed group positions, and row facets
plots <- list()
for (layout in c("means", "means_ci", "means_ci_log10")) {
  plot <- create.vf.downsampling(draws$summary, pool$palette, "mapped_only",
                                  layout)
  plots[[layout]] <- plot
  built <- ggplot_build(plot)
  geoms <- vapply(plot$layers, function(layer) class(layer$geom)[1], "")
  stopifnot(sum(geoms == "GeomCol") == 1L,
            !any(geoms %in% c("GeomViolin", "GeomPoint")),
            identical(as.character(built$layout$layout$lifestyle),
                        c("All", "Lytic", "Temperate")),
            identical(built$layout$layout$ROW, 1:3),
            all(built$layout$layout$COL == 1L))
  data <- plot$data
  expected <- filter(draws$summary, mapping == "mapped_only")
  stopifnot(identical(data$mean, expected$mean),
            identical(data$lower, expected$lower),
            identical(data$upper, expected$upper))
  transform <- if (layout == "means_ci_log10") {
    function(x) log10(100 * x + 1)
  } else function(x) 100 * x
  stopifnot(isTRUE(all.equal(built$data[[1]]$y, transform(expected$mean))),
            all(built$data[[1]]$ymin == 0),
            all(is.finite(built$data[[1]]$y)))
  centers <- as.numeric(expected$vf.category) +
    (match(expected$category, c("pal", "pre", "ind")) - 2) * .25
  stopifnot(isTRUE(all.equal(as.numeric(built$data[[1]]$x), centers)),
            identical(built$data[[1]]$fill,
              unname(c(pal = "#756BB1", pre = "#31A354", ind = "#3182BD")[
                as.character(expected$category)])))
  scale <- plot$scales$get_scales("y")
  stopifnot(isTRUE(all.equal(scale$limits, transform(c(0, 1)))))
  if (layout == "means_ci_log10") {
    percent <- c(0, .01, 1, 5, 10, 50, 100)
    stopifnot(isTRUE(all.equal(scale$trans$transform(percent),
                                log10(percent + 1))),
              isTRUE(all.equal(scale$trans$inverse(log10(percent + 1)),
                                percent)),
              identical(scale$labels(c(0, 1, 100)), c("0%", "1%", "100%")))
  }
  if (layout == "means") {
    stopifnot(!"GeomErrorbar" %in% geoms)
  } else {
    stopifnot(sum(geoms == "GeomErrorbar") == 1L)
    index <- which(geoms == "GeomErrorbar")
    intervals <- plot$layers[[index]]$data
    expected <- filter(expected, category != "pal")
    stopifnot(all(intervals$category != "pal"),
              nrow(intervals) == nrow(expected),
              isTRUE(all.equal(built$data[[index]]$ymin,
                                unname(transform(expected$lower)))),
              isTRUE(all.equal(built$data[[index]]$ymax,
                                unname(transform(expected$upper)))),
              isTRUE(all.equal(as.numeric(built$data[[index]]$x),
                centers[plot$data$category != "pal"])))
  }
}
stopifnot(identical(plots$means$data, plots$means_ci$data),
          identical(plots$means_ci$data, plots$means_ci_log10$data),
          identical(plots$means_ci$layers[[2]]$data,
                      plots$means_ci_log10$layers[[2]]$data))

# the contig runner reconciles full inputs, then removes excluded origins
fixture.dir <- tempfile(tmpdir = "tests")
dir.create(fixture.dir)
contigs <- metadata %>% transmute(
  sample = paste0(category, ".", origin, "_x"), contig_id = "same",
  category, origin, lifestyle = "Lytic", qualifying_vf_orfs = 1L
)
inventory <- contigs %>% transmute(sample, contig_id, feature_id = "1",
  vf_id = "a", vfdb_version = "VFDB_setA",
  orf_pool = "all_bacterial_prokka_cds")
write_csv(inventory, file.path(fixture.dir, "orfs.csv"))
pdf(NULL)
invisible(capture.output(run.contig.category.analysis(
  file.path(fixture.dir, "orfs.csv"), contigs, reference, fixture.dir,
  excluded.origins = c("BEL", "ENG")
)))
dev.off()
for (path in list.files(fixture.dir, "_counts.csv$", full.names = TRUE)) {
  table <- read.csv(path)
  if ("group" %in% names(table)) {
    stopifnot(!any(table$group %in% c("BEL", "ENG")))
  }
  if ("sample.id" %in% names(table)) {
    stopifnot(!any(grepl("BEL|ENG", table$sample.id)))
  }
}
unlink(fixture.dir, recursive = TRUE)

# no country-list placeholder or inclusive CheckV output remains in the reports
for (path in c("analysis/analysis_contigs.Rmd",
                "analysis/analysis_checkvhits.Rmd")) {
  code <- paste(readLines(path), collapse = "\n")
  stopifnot(!str_detect(code, 'cats\\s*=\\s*c\\([^)]*"(BEL|ENG)"'))
}
checkv <- paste(readLines("analysis/analysis_checkvhits.Rmd"), collapse = "\n")
stopifnot(!grepl("mapped_inclusive|vf.composition <-|vf.category.unmapped <-",
                 checkv),
          grepl('mapped.only = TRUE', checkv, fixed = TRUE),
          grepl('c("means", "means_ci", "means_ci_log10")',
                checkv, fixed = TRUE))
cat("PASS: origin exclusions, mapped-only pool, means, intervals, and percentage log axis\n")

# exercise report configuration and SourceTracker filtering with excluded IDs
report <- readLines("analysis/analysis_contigs.Rmd")
fixture.dir <- tempfile(tmpdir = "tests")
dir.create(file.path(fixture.dir, "sourcetracker_output"), recursive = TRUE)
source.data <- tibble(SampleID = c("pal-AUT_x_fastq_clean",
  "pal-BEL_x_fastq_clean", "pal.ENG_y_fastq_clean", "pal_BEL_z_fastq_clean"),
  Industrial = .2, NonIndustrial = .3, Soil = .4, Unknown = .1)
for (name in c("mixing_proportions.txt", "mixing_proportions_stds.txt")) {
  write.table(source.data, file.path(fixture.dir, "sourcetracker_output", name),
               sep = "\t", row.names = FALSE)
}
env <- new.env()
env$data.dir <- fixture.dir
start <- which(startsWith(report, "EXCLUDED.ORIGINS <-"))
end <- start + which(report[start:length(report)] == ")")[1] - 1L
eval(parse(text = report[start:end]), env)
start <- which(startsWith(report, "mixing.props <- read.table("))
end <- start + which(report[start:length(report)] == "```")[1] - 2L
invisible(capture.output(eval(parse(text = report[start:end]), env)))
stopifnot(identical(env$mixing.props$SampleID, "pal-AUT_x_fastq_clean"),
          identical(env$mixing.sds$SampleID, "pal-AUT_x_fastq_clean"))
unlink(fixture.dir, recursive = TRUE)
cat("PASS: SourceTracker removes BEL/ENG across sample-ID formats\n")
