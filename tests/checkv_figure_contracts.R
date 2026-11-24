###############################################################################
#   aydin Karatas
#   project Coprolite Viromes
#   checkv_figure_contracts.R
###############################################################################

suppressPackageStartupMessages(library(tidyverse))
for (path in list.files("analysis/misc", "\\.R$", full.names = TRUE)) {
  source(path)
}
source("analysis/graphing/create_checkv_genome_map.R")

stats <- crossing(category = c("pal", "pre", "ind"), index = 1:6) %>%
  mutate(genome.id = paste0(category, index), checkv.filter = "conservative",
         qualifying.vf.orfs = c(3L, 2L, 1L, 1L, 0L, 1L)[index],
         checkv.lifestyle = c("lytic", "temperate", "virulent", "unknown",
                              NA, "temperate")[index],
         vfdb_version = "VFDB_setA", orf_pool = "all_bacterial_prokka_cds")
metadata <- stats %>% mutate(genome.length = 1000L)
vf <- stats %>% uncount(qualifying.vf.orfs, .remove = FALSE, .id = "orf") %>%
  mutate(feature_id = paste0("f", orf), annotation = "vf", start = orf * 100,
         end = start + 60, strand = "-", product = "VF", ec.number = "",
         vf.id = if_else(index == 1 & orf > 1 | index == 6, "missing", "a"),
         vf_description = "hit", full_seq_evalue = 1e-20,
         full_seq_score = 100, full_seq_bias = 0) %>%
  select(-category, -index, -qualifying.vf.orfs, -checkv.lifestyle,
         -vfdb_version, -orf_pool, -orf)
viral <- metadata %>%
  transmute(checkv.filter, genome.id, feature_id = "v1", start = 50,
            end = 180, strand = "+", product = "enzyme", ec.number = "1.2.3.4")
reference <- tibble(VFID = c("a", "b"), VFcategory = c("Adhesion", "Toxin"))
mapped <- prepare.checkv.vf.categories(vf, reference)

# mapped-only denominators and full-pool totals include explicit zeros.
composition <- prepare.checkv.vf.composition(
  stats, mapped$features, category.names = names(mapped$palette),
  mapped.only = TRUE
)
stopifnot(!"Unmapped VF category" %in% composition$vf.category,
          "Toxin" %in% composition$vf.category,
          all(composition$total.vf.orfs[composition$lifestyle == "All"] == 4),
          all(composition %>% group_by(category, lifestyle) %>%
                summarise(p = sum(proportion), .groups = "drop") %>%
                pull(p) == 1))
summary <- prepare.checkv.vf.summaries(stats, mapped$features,
                                     names(mapped$palette))
full <- summary$genome.totals %>% filter(lifestyle == "Full pool")
stopifnot(all(full$total.genomes == 6), all(full$vf.positive.genomes == 5),
          all(full$no.vf.genomes == 1), all(full$mapped.vf.orfs == 5),
          all(full$unmapped.vf.orfs == 3),
          all(full$mapped.only.vf.genomes == 3),
          all(full$unmapped.only.vf.genomes == 1),
          all(full$mixed.vf.genomes == 1))
stopifnot(all(summary$genome.totals %>% filter(lifestyle == "Unknown") %>%
                pull(total.genomes) == 2))
empty <- prepare.checkv.vf.composition(
  stats, mutate(mapped$features, vf.category = "Unmapped VF category"),
  category.names = names(mapped$palette), mapped.only = TRUE
)
stopifnot(nrow(empty) == 18, all(empty$total.vf.orfs == 0),
          all(empty$proportion == 0))

# mapped ranking admits unknown lifestyles and breaks ties by genome ID.
maps <- prepare.checkv.genome.maps(stats, metadata, vf, viral, reference,
                                  selection.by = "mapped")
stopifnot(identical(maps$selection$genome.id,
                    c("pal2", "pal1", "pal3", "pre2", "pre1", "pre3",
                      "ind2", "ind1", "ind3")),
          all(table(maps$selection$category) == 3),
          any(maps$annotations$vf.category == "Unmapped VF category"))

# checkV accepts every HMM database hit, with no score threshold.
hits <- maps$selection %>%
  transmute(contig_id = genome.id, gene_num = 1L, start = 10, end = 90,
            strand = -1L, gc = 40, hmm_cat = 1, hmm_db = "vog",
            hmm_name = "VOG", evalue = 0.5, score = -1)
hits <- bind_rows(hits, mutate(hits, gene_num = 2L, hmm_db = " NA "),
                  mutate(hits, gene_num = 3L, hmm_db = " "))
lookup <- tibble(database = "vog", hmm = "VOG",
                 desc = "test description", category = "viral")
with.hits <- prepare.checkv.genome.maps(
  stats, metadata, vf, viral, reference, selection = maps$selection,
  checkv.features = hits, checkv.hmms = lookup
)
checkv <- filter(with.hits$annotations, source.annotation.mode == "checkv")
stopifnot(nrow(checkv) == 9, all(checkv$strand == "-"),
          all(grepl("\\.C001$", checkv$annotation.id)),
          all(checkv$score == -1), all(checkv$plotted.feature))
missing.hits <- prepare.checkv.genome.maps(
  stats, metadata, vf, viral, reference, selection = maps$selection,
  checkv.features = hits %>% filter(contig_id != "pal2"),
  checkv.hmms = lookup
)
stopifnot(sum(missing.hits$annotations$source.annotation.mode == "checkv") == 8)
expect.error <- function(expr) {
  stopifnot(inherits(tryCatch(force(expr), error = identity), "error"))
}
for (bad in list(mutate(hits, end = 1001), mutate(hits, strand = 0),
                 mutate(hits, score = "bad"), mutate(hits, evalue = -1),
                 mutate(hits, contig_id = "other"),
                 bind_rows(hits, hits[1, ]))) {
  expect.error(prepare.checkv.genome.maps(
    stats, metadata, vf, viral, reference, selection = maps$selection,
    checkv.features = bad, checkv.hmms = lookup
  ))
}

# built layers preserve order, strands, and full genome extents.
for (layout in c("separate_tracks", "overlay")) {
  plot <- create.checkv.genome.map(with.hits, layout)
  built <- ggplot_build(plot)
  stopifnot(all(built$data[[2]]$fill == "#756BB1"),
            all(built$data[[3]]$fill == "#3182BD"),
            all(built$data[[2]]$forward == FALSE),
            all(vapply(built$layout$panel_scales_x,
                       function(scale) identical(scale$range$range, c(1, 1000)),
                       logical(1))))
  if (layout == "separate_tracks") {
    stopifnot(all(built$data[[2]]$y > built$data[[3]]$y),
              all(built$data[[3]]$y > built$data[[4]]$y))
  }
  ggplot_build(create.checkv.genome.map(maps, layout))
}

# a supplied CheckV table can contain only unannotated genes.
no.hits <- hits %>% mutate(hmm_db = NA_character_, score = NA,
                           evalue = NA)
no.hit.maps <- prepare.checkv.genome.maps(
  stats, metadata, vf, viral, reference, selection = maps$selection,
  checkv.features = no.hits, checkv.hmms = lookup
)
stopifnot(!any(no.hit.maps$annotations$source.annotation.mode == "checkv"))
expect.error(prepare.checkv.genome.maps(
  stats, metadata, vf, viral, reference, selection = maps$selection,
  checkv.features = bind_rows(hits, hits %>% filter(gene_num == 2L)),
  checkv.hmms = lookup
))
# zero-hit pools retain all reference categories and summary rows.
zero.stats <- stats %>% mutate(qualifying.vf.orfs = 0L)
zero.summary <- prepare.checkv.vf.summaries(
  zero.stats, mapped$features[0, ], names(mapped$palette)
)
stopifnot(nrow(zero.summary$category.counts) == 45,
          all(zero.summary$category.counts$vf.orfs == 0),
          all(zero.summary$genome.totals$vf.positive.genomes == 0))
zero.composition <- prepare.checkv.vf.composition(zero.stats,
                                                mapped$features[0, ])
stopifnot(nrow(zero.composition) == 9,
          all(zero.composition$proportion == 0))
expect.error(prepare.checkv.genome.maps(
  zero.stats, metadata, vf[0, ], viral, reference, selection.by = "mapped"
))

# unknown lifestyles remain eligible for map selection.
unknown.stats <- stats %>%
  mutate(genome.id = if_else(index == 4, paste0(category, "0"), genome.id))
unknown.vf <- vf %>% mutate(genome.id = sub("4$", "0", genome.id))
unknown.viral <- viral %>% mutate(genome.id = sub("4$", "0", genome.id))
unknown.maps <- prepare.checkv.genome.maps(
  unknown.stats, unknown.stats %>% mutate(genome.length = 1000L),
  unknown.vf, unknown.viral, reference, selection.by = "mapped"
)
stopifnot(all(paste0(c("pal", "pre", "ind"), "0") %in%
                unknown.maps$selection$genome.id))
cat("PASS: CheckV composition, summaries, selection, validation, and plots\n")
