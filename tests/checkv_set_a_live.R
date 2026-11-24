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
data_dir <- "../project_coprolite_viromes_NOT_CODE/data/20261019"
figs_dir <- tempfile()
a <- which(grepl("^checkv.input.paths <-", x))
b <- which(grepl("^vf.plot.data <-", x))
c <- which(grepl('^  mutate\\(vfdb.version = bundle\\$label', x))[1]
eval(parse(text = x[a:c]))
samples <- prepare.checkv.sample.vf(vf.plot.data)
cat("PASS: sample prevalence:", nrow(samples), "samples\n")
vf_reference <- read.csv(file.path(data_dir, "VFs.csv"))
colnames(vf_reference) <- vf_reference[1, ]
vf_reference <- vf_reference[-1, c("VFID", "VFCID", "VF_Name", "VFcategory")]
viral.cds <- read.csv(file.path(data_dir, "checkv_viral_cds_conservative.csv")) %>%
  rename(checkv.filter = checkv_filter, genome.id = genome_id,
         ec.number = ec_number)
for (ranking in c("total", "mapped")) {
  maps <- prepare.checkv.genome.maps(vf.plot.data, checkv.metadata,
    checkv.features, viral.cds, vf_reference, selection.by = ranking)
  cat("PASS:", ranking, "ranking:", nrow(maps$selection), "genomes\n")
  if (ranking == "total") {
    hits <- read.delim(file.path(data_dir, "gene_features_selected9.tsv"))
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
    expected.names <- vf_reference$VF_Name[
      match(vf.annotations$vf.id, trimws(vf_reference$VFID))
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
unlink(figs_dir, recursive = TRUE)
