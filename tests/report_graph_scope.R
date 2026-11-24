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

# the downsampling report produces mapped-only draws and a literal first draw
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
for (layout in c("example", "stacked", "violin")) {
  plot <- create.vf.downsampling(draws$summary, pool$palette, "mapped_only",
                                  layout, iterations = draws$iterations)
  built <- ggplot_build(plot)
  stopifnot(identical(plot$scales$get_scales("y")$limits, c(0, 1)))
  if (layout == "example") {
    stopifnot(identical(plot$data$mean, draws$example$proportion),
              grepl("iteration 1", plot$labels$subtitle, ignore.case = TRUE))
  }
  if (layout == "violin") {
    geoms <- vapply(plot$layers, function(layer) class(layer$geom)[1], "")
    stopifnot("GeomViolin" %in% geoms, !"GeomCol" %in% geoms,
              !"GeomErrorbar" %in% geoms)
    intervals <- plot$layers[[which(geoms == "GeomSegment")]]$data
    points <- plot$layers[[which(geoms == "GeomPoint")]]$data
    stopifnot(all(intervals$category != "pal"),
              any(points$category == "pal"),
              all(is.finite(points$median)),
              all(points$median[points$empty] == 0))
    row <- filter(points, category == "pre", lifestyle == "All",
                   vf.category == "Adhesion")
    values <- filter(draws$iterations, category == "pre", lifestyle == "All",
                      vf.category == "Adhesion")$proportion
    stopifnot(row$median == median(values),
              row$lower == unname(quantile(values, .025)),
              row$upper == unname(quantile(values, .975)))
  }
}

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
          grepl('"violin"', checkv, fixed = TRUE),
          grepl('"example"', checkv, fixed = TRUE))
cat("PASS: origin exclusions, mapped-only pool, one draw, and styled violins\n")

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
