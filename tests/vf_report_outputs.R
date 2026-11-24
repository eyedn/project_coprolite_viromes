###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   vf_report_outputs.R
###############################################################################

# independently reconcile isolated render exports and retained report sections
suppressPackageStartupMessages(library(tidyverse))
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) %in% c(1L, 2L))
shared.root <- length(args) == 2L && args[2] == "shared"
root <- normalizePath(args[1], mustWork = TRUE)
checkv.dir <- if (shared.root) file.path(root, "checkv") else {
  file.path(root, "checkv", "figures", "checkv")
}
contig.dir <- if (shared.root) file.path(root, "VFDB_setA") else {
  file.path(root, "contigs", "figures", "VFDB_setA")
}
read.table.export <- function(directory, stem) {
  read.csv(file.path(directory, paste0(stem, ".csv")), check.names = FALSE)
}
stem <- "checkv_vf_category_downsampling_VFDB_setA_conservative"
selections <- read.table.export(checkv.dir, paste0(stem, "_selections"))
draws <- read.table.export(checkv.dir, paste0(stem, "_iterations"))
summary <- read.table.export(checkv.dir, paste0(stem, "_summary"))
sizes <- selections %>% count(iteration, category, lifestyle)
stopifnot(n_distinct(selections$iteration) == 1000L,
          nrow(sizes) == 6000L,
          all(sizes$n == if_else(sizes$lifestyle == "lytic", 30L, 5L)),
          !anyDuplicated(selections[c("iteration", "genome.id")]),
          all(count(filter(selections, category == "pal"), genome.id)$n == 1000),
          all(draws$proportion[draws$total.vf.orfs == 0] == 0))
expected <- draws %>% group_by(mapping, category, lifestyle, vf.category) %>%
  summarise(mean = mean(proportion), lower = quantile(proportion, .025),
            upper = quantile(proportion, .975),
            empty.draws = sum(total.vf.orfs == 0), .groups = "drop")
comparison <- inner_join(expected, summary,
  by = c("mapping", "category", "lifestyle", "vf.category"),
  suffix = c(".expected", ".export"))
for (column in c("mean", "lower", "upper", "empty.draws")) {
  stopifnot(max(abs(comparison[[paste0(column, ".expected")]] -
                    comparison[[paste0(column, ".export")]])) < 1e-12)
}
# all pools selected genome counts before normalization in every draw
pooled <- draws %>% filter(lifestyle != "All") %>%
  group_by(iteration, category, mapping, vf.category) %>%
  summarise(expected = sum(category.orfs), .groups = "drop") %>%
  inner_join(filter(draws, lifestyle == "All"),
    by = c("iteration", "category", "mapping", "vf.category"))
stopifnot(all(pooled$expected == pooled$category.orfs))
paleo.temperate <- filter(summary, category == "pal", lifestyle == "Temperate")
stopifnot(all(paleo.temperate$mean == 0),
          all(paleo.temperate$empty.draws == 1000L),
          length(list.files(checkv.dir, "downsampling_.*\\.svg$")) == 3L,
          identical(unique(draws$mapping), "mapped_only"),
          !"Unmapped VF category" %in% draws$vf.category,
          !any(grepl("(^|[._-])(BEL|ENG)([._-]|$)", selections$genome.id)))
example <- read.table.export(checkv.dir, paste0(stem, "_example"))
stopifnot(all(example$iteration == 1L),
          nrow(example) == nrow(filter(draws, iteration == 1L)),
          !any(grepl("inclusive|grouped", list.files(checkv.dir))))

# retained presence counts and count summaries retain the same genome pool
presence <- read.table.export(checkv.dir,
  "vf_genome_presence_absence_by_category_lifestyle_VFDB_setA_conservative")
stopifnot(nrow(presence) == 18L,
          all(presence$vfdb_version == "VFDB_setA"),
          sum(presence$segment.count[presence$lifestyle == "All"]) ==
            sum(presence$segment.count[presence$lifestyle != "All"]))
selection <- read.table.export(checkv.dir,
  "vf_top_genome_selection_VFDB_setA_conservative")
stopifnot(nrow(selection) == 9L, all(table(selection$category) == 3L))
for (name in c("vf_category_counts", "vf_genome_totals")) {
  stopifnot(nrow(read.table.export(checkv.dir,
    paste0(name, "_VFDB_setA_conservative"))) > 0)
}

# each of the eight contig layouts has complete, bounded category proportions
files <- list.files(contig.dir, "^contig_vf_composition_.*_counts.csv$",
                     full.names = TRUE)
stopifnot(length(files) == 8L,
          length(list.files(contig.dir, "^contig_vf_composition_.*\\.svg$")) == 8L)
compositions <- lapply(files, read.csv)
for (data in compositions) {
  totals <- data %>% group_by(group, lifestyle) %>%
    summarise(count = sum(category.orfs), total = first(total.vf.orfs),
              proportion = sum(proportion), .groups = "drop")
  stopifnot(!any(data$group %in% c("BEL", "ENG")),
            all(totals$count == totals$total),
            all(abs(totals$proportion - if_else(totals$total > 0, 1, 0)) < 1e-12),
            all(data$vfdb_version == "VFDB_setA"))
  if (unique(data$mapping) == "mapped_only") {
    stopifnot(!"Unmapped VF category" %in% data$vf.category)
  }
}

# sample tests normalize pooled mapped counts and preserve zero-total omissions
for (type in c("contig", "checkv")) {
  directory <- if (type == "contig") contig.dir else checkv.dir
  stem <- paste0(type, "_sample_vf_category_differential_VFDB_setA",
                   if (type == "checkv") "_conservative" else "")
  counts <- read.table.export(directory, paste0(stem, "_counts"))
  normalized <- read.table.export(directory, paste0(stem, "_normalized"))
  omitted <- read.table.export(directory, paste0(stem, "_omitted"))
  tests <- read.table.export(directory, paste0(stem, "_tests"))
  stopifnot(!any(counts$sample.id %in%
                     c("pal.ENG_LG4560.69", "pal.AUT_2612")),
            all(omitted$mapped.total == 0),
            all(normalized$mapped.total > 0),
            all(abs(normalized$log.cpm - log10(normalized$cpm + 1)) < 1e-12),
            all(abs(normalized$cpm -
                      1e6 * normalized$n / normalized$mapped.total) < 1e-8),
            isTRUE(all.equal(tests$kruskal.q.bh,
                              p.adjust(tests$kruskal.p.raw, "BH"))))
}
html.path <- if (shared.root) file.path(root, "analysis_checkvhits.html") else {
  file.path(root, "checkv", "analysis_checkvhits.html")
}
html <- readLines(html.path, warn = FALSE)
stopifnot(!any(grepl("Historical selected-network|lifestyle agreement",
                     html, ignore.case = TRUE)))

# inspect every exported graph and sample-bearing table for excluded origins
excluded.pattern <- "(^|[^A-Za-z])(BEL|ENG)([^A-Za-z]|$)"
graphs <- list.files(root, "\\.svg$", recursive = TRUE, full.names = TRUE)
stopifnot(length(graphs) > 0L)
for (path in graphs) {
  stopifnot(!any(grepl(excluded.pattern, readLines(path, warn = FALSE))))
}
tables <- list.files(root, "\\.csv$", recursive = TRUE, full.names = TRUE)
for (path in tables) {
  data <- read.csv(path, check.names = FALSE)
  stopifnot(!any(grepl(excluded.pattern, names(data))))
  columns <- intersect(names(data),
    c("origin", "sample", "sample.id", "genome.id", "genome_id", "SampleID"))
  for (column in columns) {
    stopifnot(!any(grepl(excluded.pattern, data[[column]])))
  }
}
cat("PASS: live output sizes, zeros, denominators, percentiles, retained outputs\n")
