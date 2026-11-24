###############################################################################
#   aydin Karatas
#   project Coprolite Viromes
#   prepare_checkv_vf_composition.R
###############################################################################


prepare.checkv.vf.composition <- function(stats, vf, category.names = NULL,
                                          mapped.only = FALSE) {
  keys <- c("checkv.filter", "genome.id")
  categories <- c("pal", "pre", "ind")
  if (anyDuplicated(stats[keys]) ||
      anyDuplicated(vf[c(keys, "feature_id")]) ||
      anyNA(stats[c(keys, "category", "qualifying.vf.orfs")]) ||
      any(!stats$category %in% categories) || anyNA(vf$vf.category)) {
    stop("Invalid VF composition genome or feature inputs")
  }
  counts <- vf %>% count(across(all_of(keys)), name = "feature.count")
  reconciliation <- stats %>% left_join(counts, by = keys)
  if (nrow(anti_join(vf, stats, by = keys)) > 0L ||
      any(replace_na(reconciliation$feature.count, 0L) !=
          reconciliation$qualifying.vf.orfs)) {
    stop("VF composition features disagree with qualifying ORF counts")
  }

  # all pools recognized lifestyles; each ORF contributes once per bar
  genomes <- stats %>%
    mutate(lifestyle = normalize.checkv.lifestyle(checkv.lifestyle)) %>%
    filter(lifestyle %in% c("lytic", "temperate"), qualifying.vf.orfs > 0L) %>%
    select(all_of(keys), category, lifestyle)
  genomes <- bind_rows(genomes, genomes %>% mutate(lifestyle = "all")) %>%
    mutate(category = factor(category, levels = categories),
           lifestyle = factor(lifestyle,
                              levels = c("all", "lytic", "temperate"),
                              labels = c("All", "Lytic", "Temperate")))
  totals <- genomes %>% count(category, lifestyle,
                              name = "vf.positive.genomes") %>%
    complete(category, lifestyle, fill = list(vf.positive.genomes = 0L))
  if (is.null(category.names)) {
    category.names <- sort(unique(vf$vf.category), method = "radix")
    if (length(category.names) == 0L) category.names <- "Unmapped VF category"
  }
  if (mapped.only) {
    vf <- vf %>% filter(vf.category != "Unmapped VF category")
    category.names <- setdiff(category.names, "Unmapped VF category")
  }
  if (length(category.names) == 0L) {
    stop("VF composition requires reference category names")
  }
  composition <- genomes %>%
    inner_join(vf %>% select(all_of(keys), feature_id, vf.category),
               by = keys, relationship = "many-to-many") %>%
    count(category, lifestyle, vf.category, name = "category.orfs") %>%
    complete(category, lifestyle, vf.category = category.names,
             fill = list(category.orfs = 0L)) %>%
    left_join(totals, by = c("category", "lifestyle")) %>%
    group_by(category, lifestyle) %>%
    mutate(total.vf.orfs = sum(category.orfs),
           proportion = category.orfs / pmax(total.vf.orfs, 1L)) %>%
    ungroup()
  return(composition)
}
