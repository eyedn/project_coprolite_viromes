###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   checkv_set_a_live.R
###############################################################################

# inspect local set-A inputs and map preparations without exporting figures.
suppressPackageStartupMessages(library(tidyverse))
for (dir in c("analysis/misc", "analysis/stats")) {
  for (path in list.files(dir, "\\.R$", full.names = TRUE)) source(path)
}
source("analysis/graphing/create_checkv_genome_map.R")
x <- readLines("analysis/analysis_checkvhits.Rmd")
data.dir <- "../project_coprolite_viromes_NOT_CODE/data/20261019"
figs.dir <- tempfile()
a <- which(grepl("^checkv.input.paths <-", x))
b <- which(grepl("^vf.plot.data <-", x))
c <- which(grepl('^  mutate\\(vfdb.version = bundle\\$label', x))[1]
eval(parse(text = x[a:c][!grepl("^```", x[a:c])]))
samples <- prepare.checkv.sample.vf(vf.plot.data)
cat("PASS: sample prevalence:", nrow(samples), "samples\n")
# use the same excluded-origin, mapped-only population as the report
config.start <- which(startsWith(x, "EXCLUDED.ORIGINS <-"))
config.end <- config.start + which(x[config.start:length(x)] == ")")[1] - 1L
eval(parse(text = x[config.start:config.end]))
ref.start <- which(startsWith(x, "```{r prepare-vf-reference-categories}")) + 1L
ref.end <- ref.start + which(x[ref.start:length(x)] == "```")[1] - 2L
eval(parse(text = x[ref.start:ref.end]))
stopifnot(!any(vf.plot.data$origin %in% EXCLUDED.ORIGINS),
          !"Unmapped VF category" %in% vf.category.features$vf.category)
viral.cds <- read.csv(file.path(data.dir, "checkv_viral_cds_conservative.csv")) %>%
  rename(checkv.filter = checkv_filter, genome.id = genome_id,
         ec.number = ec_number)
for (ranking in c("total", "mapped")) {
  maps <- prepare.checkv.genome.maps(vf.plot.data, checkv.metadata,
    checkv.features, viral.cds, vf.reference, selection.by = ranking)
  cat("PASS:", ranking, "ranking:", nrow(maps$selection), "genomes\n")
  if (ranking == "total") {
    hits <- read.delim(file.path(data.dir, "gene_features_selected9.tsv"))
    cat("TSV genomes outside selection:",
        paste(setdiff(hits$contig_id, maps$selection$genome.id), collapse = ","),
        "\n")
    block.start <- which(grepl("^checkv.gene.features <-", x))
    block.end <- which(grepl("^vf.top.genome.selection <-", x)) - 1L
    eval(parse(text = x[block.start:block.end]))
    stopifnot(vf.genome.maps$has.checkv,
              sum(vf.genome.maps$annotations$source.annotation.mode ==
                    "checkv") == 413L)
    cat("PASS: updated TSV matches the total-VF top-nine selection\n")
  }
  for (layout in c("separate_tracks", "overlay")) {
    plot <- create.checkv.genome.map(maps, layout)
    stopifnot(grepl("VFDB set A", plot$labels$subtitle))
    built <- ggplot_build(plot)
    vf.annotations <- maps$annotations %>%
      filter(source.annotation.mode == "vf", plotted.feature)
    vf.labels <- built$data[[7]]$label
    expected.names <- vf.reference$VF_Name[
      match(vf.annotations$vf.id, trimws(vf.reference$VFID))
    ]
    stopifnot(identical(vf.annotations$vf.name,
                        replace_na(as.character(expected.names), "")))
    for (i in seq_len(nrow(vf.annotations))) {
      label <- gsub("[[:space:]]+", " ", vf.labels[i])
      name <- gsub("[[:space:]]+", " ", trimws(expected.names[i]))
      if (!is.na(name) && nzchar(name)) {
        category <- gsub("[[:space:]]+", " ", vf.annotations$vf.category[i])
        stopifnot(grepl(paste(name, category), label, fixed = TRUE))
      }
    }
    viral.labels <- built$data[[6]]$label
    viral.annotations <- maps$annotations %>%
      filter(source.annotation.mode == "viral", plotted.feature)
    stopifnot(length(viral.labels) == nrow(viral.annotations))
    for (i in seq_len(nrow(viral.annotations))) {
      label <- gsub("[[:space:]]+", " ", viral.labels[i])
      product <- gsub("[[:space:]]+", " ", viral.annotations$product[i])
      stopifnot(grepl(viral.annotations$annotation.id[i], label, fixed = TRUE),
                grepl(product, label, fixed = TRUE),
                grepl(paste0("EC ", viral.annotations$ec.number[i]),
                      label, fixed = TRUE))
    }
  }
}
unlink(figs.dir, recursive = TRUE)
