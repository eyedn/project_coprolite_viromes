###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   prepare_checkv_analysis_pool.R
###############################################################################


# reconcile source calls before selecting the mapped-only analysis population
prepare.checkv.analysis.pool <- function(stats, metadata, features, reference,
                                          excluded.origins = character()) {
  keys <- c("checkv.filter", "genome.id")
  mapped <- prepare.checkv.vf.categories(features, reference)
  counts <- mapped$features %>% count(across(all_of(keys)), name = "observed")
  reconciled <- stats %>% left_join(counts, by = keys)
  if (anyDuplicated(stats[keys]) || anyDuplicated(metadata[keys]) ||
      nrow(anti_join(mapped$features, stats, by = keys)) ||
      any(replace_na(reconciled$observed, 0L) != stats$qualifying.vf.orfs)) {
    stop("CheckV source VF features disagree with source ORF counts")
  }
  allowed <- stats %>% filter(!origin %in% excluded.origins) %>%
    select(all_of(keys))
  stats <- semi_join(stats, allowed, by = keys)
  metadata <- semi_join(metadata, allowed, by = keys)
  features <- semi_join(features, allowed, by = keys)
  vf <- semi_join(mapped$features, allowed, by = keys)
  excluded.unmapped.orfs <- sum(vf$vf.category == "Unmapped VF category")
  vf <- vf %>% filter(vf.category != "Unmapped VF category")
  counts <- vf %>% count(across(all_of(keys)), name = "mapped.orfs")
  stats <- stats %>% left_join(counts, by = keys) %>%
    mutate(qualifying.vf.orfs = replace_na(mapped.orfs, 0L),
           vf_present = as.integer(qualifying.vf.orfs > 0L),
           vf.orf.prevalence = if_else(total.bacterial.orfs > 0L,
             qualifying.vf.orfs / total.bacterial.orfs, NA_real_)) %>%
    select(-mapped.orfs)
  features <- bind_rows(
    filter(features, annotation != "vf"),
    semi_join(filter(features, annotation == "vf"), vf,
               by = c(keys, "feature_id"))
  )
  palette <- mapped$palette[names(mapped$palette) != "Unmapped VF category"]
  list(stats = stats, metadata = metadata, features = features, vf = vf,
       palette = palette, excluded.unmapped.orfs = excluded.unmapped.orfs)
}
