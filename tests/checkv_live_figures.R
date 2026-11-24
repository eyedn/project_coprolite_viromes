###############################################################################
#   aydin Karatas
#   project Coprolite Viromes
#   checkv_live_figures.R
###############################################################################

# verify exported real-data tables from a temporary report render.
suppressPackageStartupMessages(library(tidyverse))
arguments <- commandArgs(trailingOnly = TRUE)
stopifnot(length(arguments) == 2L)
data.dir <- arguments[1]
figure.dir <- arguments[2]
tag <- "_VFDB_setB_conservative.csv"
read.export <- function(stem) {
  read.csv(file.path(figure.dir, paste0(stem, tag)))
}
selection <- read.export("vf_top_genome_selection")
annotations <- read.export("vf_top_genome_annotations")
mapped.selection <- read.export("vf_top_mapped_genome_selection")
mapped.annotations <- read.export("vf_top_mapped_genome_annotations")
checkv <- annotations %>% filter(source.annotation.mode == "checkv")
original <- read.delim(file.path(data.dir, "gene_features_selected9.tsv")) %>%
  filter(!is.na(hmm_db), nzchar(trimws(hmm_db)), trimws(hmm_db) != "NA")
stopifnot(nrow(checkv) == 429, n_distinct(checkv$genome.id) == 9,
          all(checkv$plotted.feature),
          setequal(original$contig_id, selection$genome.id),
          all(table(selection$category) == 3),
          all(table(mapped.selection$category) == 3),
          all(mapped.selection$mapped.vf.orfs > 0),
          !any(mapped.annotations$source.annotation.mode == "checkv"))
joined <- checkv %>% inner_join(original, by = c("genome.id" = "contig_id",
                                                "gene_num" = "gene_num"),
                                suffix = c(".export", ".input"))
stopifnot(nrow(joined) == 429)
for (column in c("start", "end", "gc", "hmm_cat", "hmm_db", "hmm_name",
                 "evalue", "score")) {
  stopifnot(isTRUE(all.equal(joined[[paste0(column, ".export")]],
                             joined[[paste0(column, ".input")]])))
}
stopifnot(all(joined$strand.export == if_else(joined$strand.input == 1,
                                             "+", "-")))

# independently rank all qualifying mapped ORFs from the source tables.
source.stats <- read.csv(file.path(data.dir, "checkv_genome_vf_stats.csv")) %>%
  filter(checkv_filter == "conservative")
source.features <- read.csv(
  file.path(data.dir, "checkv_genome_features.csv")
) %>%
  filter(checkv_filter == "conservative", annotation == "vf")
reference <- read.csv(file.path(data.dir, "VFs.csv"))
colnames(reference) <- reference[1, ]
reference <- reference[-1, ] %>%
  filter(!is.na(VFcategory), nzchar(trimws(VFcategory))) %>%
  distinct(VFID)
expected <- source.features %>% filter(vf_id %in% reference$VFID) %>%
  count(genome_id, name = "mapped") %>%
  inner_join(source.stats, by = "genome_id") %>%
  arrange(desc(mapped), genome_id, .locale = "C") %>%
  group_by(category) %>% slice_head(n = 3L) %>% ungroup() %>%
  arrange(match(category, c("pal", "pre", "ind")), desc(mapped),
          genome_id, .locale = "C")
stopifnot(identical(expected$genome_id, mapped.selection$genome.id))
category.counts <- read.export("vf_category_counts")
totals <- read.export("vf_genome_totals")
full <- totals %>% filter(lifestyle == "Full pool")
stopifnot(sum(full$total.genomes) == nrow(source.stats),
          sum(full$mapped.vf.orfs + full$unmapped.vf.orfs) ==
            nrow(source.features),
          sum(category.counts %>% filter(lifestyle == "Full pool") %>%
                pull(vf.orfs)) == nrow(source.features),
          all(totals$vf.positive.genomes + totals$no.vf.genomes ==
                totals$total.genomes),
          all(totals$mapped.only.vf.genomes + totals$unmapped.only.vf.genomes +
                totals$mixed.vf.genomes == totals$vf.positive.genomes))
composition <- read.export(
  "vf_mapped_category_composition_by_category_lifestyle"
)
sums <- composition %>% group_by(category, lifestyle) %>%
  summarise(total = first(total.vf.orfs), proportion = sum(proportion),
            .groups = "drop")
stopifnot(!"Unmapped VF category" %in% composition$vf.category,
          all(abs(sums$proportion[sums$total > 0] - 1) < 1e-10))
print(full)
print(mapped.selection)
cat("PASS: 429 CheckV hits, source annotations, both selections, and VF totals\n")

# both SVG layouts contain every plotted feature's annotation ID.
for (prefix in c("vf_top_genome", "vf_top_mapped_genome")) {
  table <- if (prefix == "vf_top_genome") annotations else mapped.annotations
  for (layout in c("separate_tracks", "overlay")) {
    path <- file.path(figure.dir, paste0(prefix, "_maps_", layout,
                                       "_VFDB_setB_conservative.svg"))
    svg <- paste(readLines(path, warn = FALSE), collapse = "\n")
    stopifnot(all(vapply(table$annotation.id[table$plotted.feature],
                         function(id) grepl(id, svg, fixed = TRUE),
                         logical(1))))
  }
}
cat("PASS: both SVG layouts retain every plotted annotation ID\n")
