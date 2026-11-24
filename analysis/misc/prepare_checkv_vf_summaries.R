###############################################################################
#   aydin Karatas
#   project Coprolite Viromes
#   prepare_checkv_vf_summaries.R
###############################################################################

prepare.checkv.vf.summaries <- function(stats, vf, category.names) {
  # reconcile every genome before constructing overlapping descriptive strata.
  invisible(prepare.checkv.vf.composition(stats, vf, category.names))
  keys <- c("checkv.filter", "genome.id")
  counts <- vf %>% group_by(across(all_of(keys))) %>%
    summarise(mapped.vf.orfs = sum(vf.category != "Unmapped VF category"),
              unmapped.vf.orfs = sum(vf.category == "Unmapped VF category"),
              .groups = "drop")
  genomes <- stats %>% left_join(counts, by = keys) %>%
    mutate(across(c(mapped.vf.orfs, unmapped.vf.orfs), ~ replace_na(.x, 0L)),
           lifestyle = normalize.checkv.lifestyle(checkv.lifestyle),
           lifestyle = case_when(lifestyle == "lytic" ~ "Lytic",
                                 lifestyle == "temperate" ~ "Temperate",
                                 TRUE ~ "Unknown"))
  recognized <- genomes %>% filter(lifestyle != "Unknown")
  strata <- bind_rows(
    genomes %>% mutate(lifestyle = "Full pool"),
    recognized %>% mutate(lifestyle = "All"), genomes
  ) %>% mutate(
    category = factor(category, levels = c("pal", "pre", "ind")),
    lifestyle = factor(lifestyle, levels = c("Full pool", "All", "Lytic",
                                             "Temperate", "Unknown"))
  )
  totals <- strata %>% group_by(category, lifestyle) %>%
    summarise(
      total.genomes = n(), vf.positive.genomes = sum(qualifying.vf.orfs > 0),
      no.vf.genomes = sum(qualifying.vf.orfs == 0),
      mapped.only.vf.genomes = sum(mapped.vf.orfs > 0 & unmapped.vf.orfs == 0),
      unmapped.only.vf.genomes = sum(
        mapped.vf.orfs == 0 & unmapped.vf.orfs > 0
      ),
      mixed.vf.genomes = sum(mapped.vf.orfs > 0 & unmapped.vf.orfs > 0),
      mapped.vf.orfs = sum(mapped.vf.orfs),
      unmapped.vf.orfs = sum(unmapped.vf.orfs),
      .groups = "drop"
    ) %>% complete(category, lifestyle, fill = list(
      total.genomes = 0L, vf.positive.genomes = 0L, no.vf.genomes = 0L,
      mapped.vf.orfs = 0L, unmapped.vf.orfs = 0L,
      mapped.only.vf.genomes = 0L, unmapped.only.vf.genomes = 0L,
      mixed.vf.genomes = 0L
    ))
  category.counts <- strata %>% select(all_of(keys), category, lifestyle) %>%
    inner_join(vf %>% select(all_of(keys), vf.category), by = keys,
               relationship = "many-to-many") %>%
    count(category, lifestyle, vf.category, name = "vf.orfs") %>%
    complete(category, lifestyle, vf.category = category.names,
             fill = list(vf.orfs = 0L))
  reconciliation <- category.counts %>% group_by(category, lifestyle) %>%
    summarise(vf.orfs = sum(vf.orfs), .groups = "drop") %>%
    left_join(totals, by = c("category", "lifestyle"))
  if (any(reconciliation$vf.orfs != reconciliation$mapped.vf.orfs +
          reconciliation$unmapped.vf.orfs)) {
    stop("VF category counts disagree with mapped and unmapped ORF totals")
  }
  return(list(category.counts = category.counts, genome.totals = totals))
}
