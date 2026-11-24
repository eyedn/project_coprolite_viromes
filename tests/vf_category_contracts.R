###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   vf_category_contracts.R
###############################################################################

suppressPackageStartupMessages(library(tidyverse))
for (path in c(
  "misc/normalize_checkv_lifestyle.R", "misc/validate_vf_pool.R",
  "misc/prepare_checkv_vf_categories.R",
  "misc/prepare_checkv_vf_composition.R", "misc/prepare_vf_composition.R",
  "misc/read_contig_vf_categories.R", "stats/downsample_checkv_vf.R",
  "stats/compare_sample_vf_categories.R", "graphing/create_vf_composition.R"
)) source(file.path("analysis", path))

fails <- function(expr, text) {
  error <- tryCatch({ force(expr); NULL }, error = identity)
  stopifnot(inherits(error, "error"), grepl(text, conditionMessage(error)))
}
reference <- tibble(VFID = c("a", "b", "z"),
                    VFcategory = c("Adhesion", "Toxin", "Absent"))
features <- tibble(checkv.filter = "conservative", genome.id = "g",
                   annotation = "vf", feature_id = c("1", "2", "3"),
                   vf.id = c("a", "b", "unknown"))
mapped <- prepare.checkv.vf.categories(features, reference)
stopifnot(mapped$features$vf.category[3] == "Unmapped VF category",
          mapped$palette[["Unmapped VF category"]] == "#808080")

# duplicate ORFs spanning stream chunks count once; sample + contig is the key
fixture.dir <- tempfile(tmpdir = "tests")
dir.create(fixture.dir)
inventory <- tibble(
  sample = c("pal.AUT_x", "pal.AUT_x", "pre.FJI_y", "pre.FJI_y"),
  contig_id = "same", feature_id = c("1", "1", "1", "2"),
  vf_id = c("a", "a", "unknown", NA_character_),
  vfdb_version = "VFDB_setA", orf_pool = "all_bacterial_prokka_cds"
)
write_csv(inventory, file.path(fixture.dir, "orfs.csv"))
contigs <- tibble(sample = c("pal.AUT_x", "pre.FJI_y", "ind.USA_z"),
                   contig_id = "same", category = c("pal", "pre", "ind"),
                   origin = c("AUT", "FJI", "USA"),
                   lifestyle = c("Lytic", "Unknown", "Temperate"),
                   qualifying_vf_orfs = c(1L, 1L, 0L))
loaded <- read.contig.vf.categories(file.path(fixture.dir, "orfs.csv"),
                                   contigs, reference, chunk.size = 1L)
stopifnot(nrow(loaded$features) == 2L,
          sum(loaded$excluded$qualifying.vf.orfs) == 1L)
fails(read.contig.vf.categories(file.path(fixture.dir, "orfs.csv"),
  mutate(contigs, qualifying_vf_orfs = 0L), reference), "disagree")
units <- loaded$units
for (mapped.only in c(FALSE, TRUE)) {
  for (group in c("category", "origin")) {
    for (separate in c(FALSE, TRUE)) {
      composition <- prepare.vf.composition(
        units, loaded$features, names(mapped$palette), group,
        separate, mapped.only
      )
      stopifnot(all(is.finite(composition$proportion)),
                all(composition$proportion >= 0 & composition$proportion <= 1))
      stopifnot(identical(levels(composition$lifestyle),
        if (separate) c("Lytic", "Temperate") else "All"))
      plot <- create.vf.composition(composition, mapped$palette, separate)
      built <- ggplot_build(plot)
      stopifnot(identical(plot$scales$get_scales("y")$limits, c(0, 1)),
                nrow(built$data[[1]]) == nrow(composition))
    }
  }
}

# exact balanced strata include zero-hit genomes and fixed paleo genomes
stats <- crossing(category = c("pal", "pre", "ind"),
                  lifestyle = c("lytic", "temperate"), index = 1:3) %>%
  mutate(genome.id = paste(category, lifestyle, index),
         checkv.lifestyle = lifestyle, checkv.filter = "conservative",
         qualifying.vf.orfs = as.integer(index == 1 & lifestyle == "lytic"))
vf <- stats %>% filter(qualifying.vf.orfs > 0) %>%
  transmute(genome.id, checkv.filter, feature_id = "1",
            vf.category = "Adhesion")
a <- downsample.checkv.vf(stats, vf, names(mapped$palette),
                           iterations = 40L, lytic = 3L, temperate = 3L,
                           paleo.lytic = 3L, paleo.temperate = 3L)
b <- downsample.checkv.vf(stats, vf, names(mapped$palette),
                           iterations = 40L, lytic = 3L, temperate = 3L,
                           paleo.lytic = 3L, paleo.temperate = 3L)
stopifnot(identical(a, b),
          all(count(a$selections, iteration, category, lifestyle)$n == 3L),
          !anyDuplicated(a$selections[c("iteration", "genome.id")]))
fails(downsample.checkv.vf(stats, vf, names(mapped$palette),
  paleo.lytic = 3L, paleo.temperate = 3L), "supply")
a <- downsample.checkv.vf(stats, vf, names(mapped$palette),
                           iterations = 100L, lytic = 1L, temperate = 1L,
                           paleo.lytic = 3L, paleo.temperate = 3L)
stopifnot(all(count(filter(a$selections, category == "pal"),
                    genome.id)$n == 100L))
zero <- filter(a$iterations, total.vf.orfs == 0)
stopifnot(nrow(zero) > 0, all(zero$proportion == 0))
for (version in unique(a$iterations$mapping)) {
  values <- filter(a$iterations, mapping == version, category == "pre",
                   lifestyle == "All", vf.category == "Adhesion")$proportion
  summary <- filter(a$summary, mapping == version, category == "pre",
                    lifestyle == "All", vf.category == "Adhesion")
  stopifnot(summary$mean == mean(values),
            summary$lower == unname(quantile(values, .025)),
            summary$upper == unname(quantile(values, .975)),
            summary$empty.draws == sum(values == 0))
  for (layout in c("stacked", "grouped")) {
    plot <- create.vf.downsampling(a$summary, mapped$palette, version, layout)
    built <- ggplot_build(plot)
    stopifnot(identical(plot$scales$get_scales("y")$limits, c(0, 1)))
    if (layout == "grouped") {
      stopifnot(nrow(built$data[[2]]) ==
                  nrow(filter(a$summary, mapping == version, category != "pal")))
    }
  }
}

# samples with one ORF are included; unmapped calls do not normalize counts
samples <- tibble(sample.id = c(paste0("pal.AUT_", 1:5),
                                 paste0("pre.FJI_", 1:5),
                                 paste0("ind.USA_", 1:5), "pal.AUT_2612",
                                 "pre.FJI_empty"),
                  category = c(rep(c("pal", "pre", "ind"), each = 5),
                               "pal", "pre"))
sample.vf <- samples %>% filter(sample.id != "pre.FJI_empty") %>%
  mutate(vf.category = if_else(category == "pal", "Adhesion", "Toxin"),
         n = 1L)
sample.vf <- bind_rows(sample.vf, tibble(sample.id = "pre.FJI_1",
  category = "pre", vf.category = "Unmapped VF category", n = 100L))
res <- compare.sample.vf.categories(samples, sample.vf, names(mapped$palette))
stopifnot(nrow(res$omitted) == 1L, nrow(res$normalized) == 45L,
          !"pal.AUT_2612" %in% res$counts$sample.id,
          all(res$normalized$cpm[res$normalized$n == 1] == 1e6),
          sum(res$unmapped$n) == 100L,
          is.na(filter(res$tests, vf.category == "Absent")$kruskal.p.raw))
stopifnot(isTRUE(all.equal(res$tests$kruskal.q.bh,
                          p.adjust(res$tests$kruskal.p.raw, "BH"))))
for (contrast in c("ind_vs_pre", "ind_vs_pal", "pre_vs_pal")) {
  stopifnot(isTRUE(all.equal(res$tests[[paste0(contrast, ".q.across")]],
    p.adjust(res$tests[[paste0(contrast, ".q.within")]], "BH"))))
}
empty <- compare.sample.vf.categories(samples, sample.vf[0, ],
                                      names(mapped$palette))
stopifnot(nrow(empty$normalized) == 0L, all(is.na(empty$tests$kruskal.p.raw)))
unlink(fixture.dir, recursive = TRUE)
cat("PASS: streaming, composition, downsampling, sample category contracts\n")

# report input declarations select A explicitly when both versions coexist
for (report in c("analysis_contigs.Rmd", "analysis_checkvhits.Rmd")) {
  lines <- readLines(file.path("analysis", report))
  prefix <- if (report == "analysis_contigs.Rmd") "vfdb" else "checkv"
  start <- which(startsWith(lines, paste0(prefix, ".input.paths <-")))
  end <- which(startsWith(lines, paste0("names(", prefix, ".input.paths)")))
  if (report == "analysis_checkvhits.Rmd") end <- end + 2L
  env <- new.env()
  env$data.dir <- tempdir()
  eval(parse(text = lines[start:end]), env)
  paths <- get(paste0(prefix, ".input.paths"), env)
  stopifnot(all(grepl("_VFDB_setA.csv$", paths)))
  stopifnot(!any(grepl("VFDB_setB|source.files.from.dir|source_files_from_dir",
                       lines)))
}

# the plotted layouts preserve order, reference colors, and mapped denominators
all.vf <- loaded$features %>% mutate(lifestyle = "lytic")
comp <- prepare.vf.composition(units, all.vf, names(mapped$palette))
stopifnot(identical(levels(comp$group), c("pal", "pre", "ind")),
          identical(unique(comp$layout), "category_pooled"))
rounding <- comp
rounding$proportion[rounding$group == "pal"] <-
  c(.1, .2, .7000000000000002, 0)
rounded <- ggplot_build(create.vf.composition(rounding, mapped$palette))
stopifnot(all(is.finite(rounded$data[[1]]$y)),
          max(rounded$data[[1]]$y) <= 1)
plot <- create.vf.composition(comp, mapped$palette)
built <- ggplot_build(plot)
stopifnot(identical(built$plot$scales$get_scales("fill")$map("Adhesion"),
                    unname(mapped$palette["Adhesion"])))
known <- loaded$features %>%
  mutate(vf.category = "Unmapped VF category")
mapped.comp <- prepare.vf.composition(units, known, names(mapped$palette),
                                       mapped.only = TRUE)
stopifnot(all(mapped.comp$total.vf.orfs == 0),
          all(mapped.comp$proportion == 0))
# named Dunn contrasts must follow returned labels, not positional ordering
stopifnot(filter(res$tests, vf.category == "Adhesion")$ind_vs_pre.p.raw == .5,
          filter(res$tests, vf.category == "Adhesion")$ind_vs_pal.p.raw < .01)
cat("PASS: report selection, layout names, shared palette, named contrasts\n")

# set B files coexist but are never read by the contig input declaration
version.dir <- tempfile(tmpdir = "tests")
dir.create(version.dir)
for (version in c("VFDB_setA", "VFDB_setB")) {
  for (stem in c("phage_vf_stats", "sample_vf_stats", "phage_vf_orfs")) {
    suffix <- if (version == "VFDB_setA") "_VFDB_setA" else ""
    write.csv(data.frame(vfdb_version = version,
                         orf_pool = "all_bacterial_prokka_cds"),
               file.path(version.dir, paste0(stem, suffix, ".csv")),
               row.names = FALSE)
  }
}
lines <- readLines("analysis/analysis_contigs.Rmd")
start <- which(startsWith(lines, "vfdb.input.paths <-"))
end <- which(startsWith(lines, "vfdb.label <-"))
data.dir <- version.dir
eval(parse(text = lines[start:end]))
for (path in vfdb.input.paths) validate.vf.pool(read.csv(path), vfdb.version)
unlink(version.dir, recursive = TRUE)
cat("PASS: contig set A selection with set B files present\n")

# mapped-only draws can be empty even when inclusive draws contain VF ORFs
unmapped.draws <- downsample.checkv.vf(
  stats, mutate(vf, vf.category = "Unmapped VF category"), names(mapped$palette),
  iterations = 8L, lytic = 3L, temperate = 3L,
  paleo.lytic = 3L, paleo.temperate = 3L
)
stopifnot(all(filter(unmapped.draws$iterations,
                     mapping == "mapped_only")$proportion == 0),
          all(filter(unmapped.draws$iterations,
                     mapping == "mapped_only")$total.vf.orfs == 0),
          sum(filter(unmapped.draws$iterations,
                     mapping == "mapped_inclusive")$category.orfs) > 0)
cat("PASS: unmapped-only draws have zero mapped denominators\n")

# exercise all eight SVG/table export paths with the small streaming fixture
source("analysis/misc/export_vf_category_analysis.R")
export.dir <- tempfile(tmpdir = "tests")
dir.create(export.dir)
write_csv(inventory, file.path(export.dir, "orfs.csv"))
pdf(NULL)
capture.output(run.contig.category.analysis(
  file.path(export.dir, "orfs.csv"), contigs, reference, export.dir
)) -> ignored.output
dev.off()
svgs <- list.files(export.dir, "\\.svg$")
stopifnot(length(svgs) == 8L, !anyDuplicated(svgs),
          all(grepl("VFDB_setA", svgs)))
unlink(export.dir, recursive = TRUE)
cat("PASS: eight distinct SVG exports and accompanying audit tables\n")

# constant positive categories remain explicit with undefined rank statistics
constant <- compare.sample.vf.categories(
  samples, samples %>% transmute(sample.id, vf.category = "Adhesion", n = 1L),
  names(mapped$palette)
)
stopifnot(filter(constant$tests, vf.category == "Adhesion")$status ==
            "constant",
          all(is.na(constant$tests$kruskal.p.raw)))
cat("PASS: constant positive categories report NA statistics\n")

# absent biological groups leave their pairwise comparisons explicitly undefined
two.samples <- samples %>% filter(category != "ind")
two.vf <- sample.vf %>% filter(category != "ind")
two.groups <- compare.sample.vf.categories(two.samples, two.vf,
                                            names(mapped$palette))
stopifnot(all(is.na(two.groups$tests$ind_vs_pal.p.raw)),
          all(is.na(two.groups$tests$ind_vs_pre.p.raw)),
          any(two.groups$tests$pre_vs_pal.status == "tested"),
          isTRUE(all.equal(two.groups$tests$pre_vs_pal.p.raw,
                            two.groups$tests$pre_vs_pal.q.within)))
cat("PASS: absent groups retain NA comparisons without test failures\n")
