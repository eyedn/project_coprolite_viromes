###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   checkv_three_tracks.R
###############################################################################

# read live inputs and run the report's combined map chunk in isolation
suppressPackageStartupMessages(library(tidyverse))
for (path in list.files("analysis/misc", "\\.R$", full.names = TRUE)) {
  source(path)
}
source("analysis/misc/validate_vf_pool.R")
source("analysis/graphing/create_checkv_genome_map.R")
x <- readLines("analysis/analysis_checkvhits.Rmd")
data.dir <- "../project_coprolite_viromes_NOT_CODE/data/20261019"
arguments <- commandArgs(trailingOnly = TRUE)
figs.dir <- if (length(arguments)) arguments[1] else tempfile("three_tracks_")
a <- which(grepl("^checkv.input.paths <-", x))
b <- which(grepl('^  mutate\\(vfdb.version = bundle\\$label', x))[1]
invisible(capture.output(eval(parse(text = x[a:b][!grepl("^```", x[a:b])]))))
# use the same excluded-origin, mapped-only population as the report
config.start <- which(startsWith(x, "EXCLUDED.ORIGINS <-"))
config.end <- config.start + which(x[config.start:length(x)] == ")")[1] - 1L
eval(parse(text = x[config.start:config.end]))
ref.start <- which(startsWith(x, "```{r prepare-vf-reference-categories}")) + 1L
ref.end <- ref.start + which(x[ref.start:length(x)] == "```")[1] - 2L
eval(parse(text = x[ref.start:ref.end]))
stopifnot(!any(vf.plot.data$origin %in% EXCLUDED.ORIGINS),
          !"Unmapped VF category" %in% vf.category.features$vf.category)
a <- which(grepl("^```\\{r top-VF-genome-maps,", x)) + 1L
b <- a + which(x[a:length(x)] == "```")[1] - 2L
# suppress printing here; the chunk's SVG export exercises the full render
pdf(file.path(figs.dir, "chunk.pdf"), width = 20, height = 90)
invisible(capture.output(eval(parse(text = x[a:b][!grepl("^```", x[a:b])]))))
dev.off()
annotations <- vf.genome.maps$annotations
hits <- filter(annotations, source.annotation.mode == "checkv")
stopifnot(nrow(hits) == 413L,
          all(c("desc", "hmm.category", "plot.label") %in% names(hits)))
stopifnot(sum(hits$hmm.category == "viral") == 342L,
          sum(hits$hmm.category == "microbial") == 71L)
missing <- is.na(hits$desc) | !nzchar(trimws(hits$desc))
stopifnot(sum(missing) == 76L,
          identical(hits$plot.label[missing], paste0(
            str_replace_all(str_wrap(paste(hits$hmm_name[missing],
                           "(no descriptive label)"), 28),
                            "(\\S{28})(?=\\S)", "\\1\n"),
            "\n", hits$hmm.category[missing]
          )),
          identical(hits$plot.label[!missing], paste0(
            str_replace_all(str_wrap(hits$desc[!missing], 28),
                            "(\\S{28})(?=\\S)", "\\1\n"), "\n",
            hits$hmm.category[!missing]
          )))
stopifnot(max(nchar(unlist(strsplit(hits$plot.label, "\n")))) <= 28L)
original <- checkv.gene.features %>%
  filter(!is.na(hmm_db), nzchar(trimws(hmm_db)), trimws(hmm_db) != "NA")
joined <- hits %>% inner_join(original,
  by = c("genome.id" = "contig_id", "gene_num"),
  suffix = c(".export", ".input"))
stopifnot(nrow(joined) == nrow(original))
for (column in c("start", "end", "gc", "hmm_cat", "hmm_db", "hmm_name",
                 "evalue", "score")) {
  stopifnot(identical(joined[[paste0(column, ".export")]],
                      joined[[paste0(column, ".input")]]))
}
stopifnot(all(joined$strand.export == if_else(joined$strand.input == 1,
                                             "+", "-")))
built <- ggplot_build(vf.top.genome.separate)
for (i in 2:4) {
  mode <- c("checkv", "viral", "vf")[i - 1L]
  expected <- filter(annotations, plotted.feature,
                     source.annotation.mode == mode)
  stopifnot(all(built$data[[i]]$fill ==
                  c("#756BB1", "#3182BD", "#DE2D26")[i - 1L]),
            identical(built$data[[i]]$xmin, as.numeric(expected$start)),
            identical(built$data[[i]]$xmax, as.numeric(expected$end)),
            identical(built$data[[i]]$forward, expected$strand == "+"),
            identical(built$data[[i + 3L]]$label, expected$plot.label))
}
stopifnot(all(built$data[[2]]$y > built$data[[3]]$y[1]),
          all(built$data[[3]]$y > built$data[[4]]$y[1]),
          nrow(built$layout$layout) == 9L)
for (mode in c("viral", "vf")) {
  rows <- filter(annotations, source.annotation.mode == mode, plotted.feature)
  expected <- if (mode == "viral") paste0(
    rows$annotation.id, "\n", str_wrap(rows$product, 28),
    "\nEC ", rows$ec.number
  ) else paste0(rows$annotation.id, "\n", str_wrap(rows$vf.name, 28),
                "\n", str_wrap(rows$vf.category, 24))
  stopifnot(identical(rows$plot.label, expected))
}
# CSV exports retain the same annotations, labels and geometry
export <- read.csv(file.path(checkv.figs.dir, paste0(
  "vf_top_genome_annotations_VFDB_setA_conservative.csv"
)), check.names = FALSE, na.strings = "")
for (column in c("plot.label", "desc", "hmm.category", "start", "end",
                 "strand", "color.class")) {
  stopifnot(isTRUE(all.equal(export[[column]], annotations[[column]],
                             check.attributes = FALSE)))
}
stopifnot(!any(grepl("overlay|mapped_genome", list.files(checkv.figs.dir))))
# save one panel at a time for visual inspection at the same physical scale
for (i in seq_len(nrow(vf.genome.maps$selection))) {
  panel <- vf.genome.maps
  panel$selection <- panel$selection[i, ]
  panel$annotations <- filter(panel$annotations,
                              genome.id == panel$selection$genome.id)
  ragg::agg_png(file.path(figs.dir, paste0("panel_", i, ".png")),
                width = 20, height = 10, units = "in", res = 100)
  print(create.checkv.genome.map(panel))
  dev.off()
}
# exact duplicate lookup entries cannot multiply arrows; conflicts must fail
prepare <- function(lookup) prepare.checkv.genome.maps(
  vf.plot.data, checkv.metadata, checkv.features, viral.cds, vf.reference,
  checkv.features = checkv.gene.features, checkv.hmms = lookup
)
duplicate <- bind_rows(checkv.hmms, checkv.hmms[1, ])
stopifnot(identical(prepare(duplicate)$annotations, annotations))
conflict <- bind_rows(checkv.hmms, mutate(checkv.hmms[1, ], desc = "conflict"))
error <- tryCatch(prepare(conflict), error = identity)
stopifnot(inherits(error, "error"), grepl("Conflicting HMM", error$message))
# exercise the report's genome-mismatch fallback without changing source files
fallback <- x[a:b]
fallback <- fallback[-seq_len(which(grepl("^# select genomes", fallback)) - 1L)]
fallback <- fallback[seq_len(
  which(grepl("^vf.top.genome.selection <-", fallback)) - 1L
)]
checkv.gene.features$contig_id[1] <- "unselected_genome"
message <- capture.output(eval(parse(text = fallback)))
stopifnot(!vf.genome.maps$has.checkv,
          any(grepl("Omitting the CheckV track", message)),
          !any(vf.genome.maps$annotations$source.annotation.mode == "checkv"))
cat("PASS: 413 hits (342 viral, 71 microbial), 76 fallbacks, geometry,\n",
    "labels, colors, lookup conflicts, and genome-mismatch fallback\n",
    "Temporary outputs:", figs.dir, "\n")
