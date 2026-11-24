###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   compare_sample_vf_categories.R
###############################################################################


# pool within biological samples before mapped-only CPM normalization
compare.sample.vf.categories <- function(samples, vf, category.names,
  exclusions = c("pal.ENG_LG4560.69", "pal.AUT_2612")) {
  samples <- samples %>% distinct(sample.id, category)
  if (anyNA(samples) || anyDuplicated(samples$sample.id) ||
      any(!samples$category %in% c("pal", "pre", "ind")) ||
      anyNA(vf[c("sample.id", "vf.category", "n")]) ||
      any(!is.finite(vf$n) | vf$n < 0 | vf$n != floor(vf$n)) ||
      nrow(anti_join(vf, samples, by = "sample.id"))) {
    stop("Invalid sample category counts or identifiers")
  }
  categories <- setdiff(category.names, "Unmapped VF category")
  if (any(!vf$vf.category %in% category.names)) {
    stop("Unknown VF category in sample counts")
  }
  cohort <- samples %>% mutate(excluded = sample.id %in% exclusions)
  samples <- samples %>% filter(!sample.id %in% exclusions)
  unmapped <- vf %>% filter(vf.category == "Unmapped VF category") %>%
    group_by(sample.id) %>% summarise(n = sum(n), .groups = "drop") %>%
    right_join(cohort, by = "sample.id") %>% mutate(n = replace_na(n, 0L))
  pooled <- vf %>% filter(vf.category %in% categories) %>%
    group_by(sample.id, vf.category) %>%
    summarise(n = sum(n), .groups = "drop")
  counts <- crossing(sample.id = samples$sample.id,
                     vf.category = categories) %>%
    left_join(samples, by = "sample.id") %>%
    left_join(pooled, by = c("sample.id", "vf.category")) %>%
    mutate(n = replace_na(n, 0L)) %>% group_by(sample.id) %>%
    mutate(mapped.total = sum(n)) %>% ungroup()
  omitted <- counts %>% filter(mapped.total == 0) %>%
    distinct(sample.id, category, mapped.total)
  normalized <- counts %>% filter(mapped.total > 0) %>%
    mutate(cpm = 1e6 * n / mapped.total, log.cpm = log10(cpm + 1))
  cohort <- cohort %>% left_join(
    counts %>% distinct(sample.id, mapped.total), by = "sample.id"
  ) %>% mutate(status = case_when(excluded ~ "excluded sample",
                                  mapped.total == 0 ~ "zero mapped VF total",
                                  TRUE ~ "tested"))
  contrasts <- c(ind_vs_pre = "ind - pre", ind_vs_pal = "ind - pal",
                 pre_vs_pal = "pal - pre")
  tests <- lapply(categories, function(category.name) {
    data <- normalized %>% filter(vf.category == category.name)
    status <- if (!nrow(data) || all(data$n == 0)) "all zero" else {
      if (length(unique(data$log.cpm)) < 2) "constant" else {
        if (n_distinct(data$category) < 2) "fewer than two groups" else "tested"
      }
    }
    result <- tibble(vf.category = category.name, status,
                      samples = nrow(data), kruskal.statistic = NA_real_,
                      kruskal.p.raw = NA_real_)
    for (contrast in names(contrasts)) {
      result[[paste0(contrast, ".p.raw")]] <- NA_real_
      result[[paste0(contrast, ".q.within")]] <- NA_real_
      result[[paste0(contrast, ".status")]] <- "not tested"
    }
    if (status == "tested") {
      kw <- kruskal.test(log.cpm ~ category, data = data)
      result$kruskal.statistic <- unname(kw$statistic)
      result$kruskal.p.raw <- kw$p.value
      if (is.finite(kw$p.value) && kw$p.value < .05) {
        # one comparison has identity BH correction; avoid the package's
        # single-comparison matrix-drop error in its BH routine
        adjustment <- if (n_distinct(data$category) == 2L) "none" else "bh"
        capture.output(dunn <- dunn.test::dunn.test(
          data$log.cpm, data$category, method = adjustment, kw = FALSE
        ))
        for (contrast in names(contrasts)) {
          index <- match(contrasts[[contrast]], dunn$comparisons)
          if (!is.na(index)) {
            result[[paste0(contrast, ".p.raw")]] <- dunn$P[index]
            result[[paste0(contrast, ".q.within")]] <- dunn$P.adjusted[index]
            result[[paste0(contrast, ".status")]] <- "tested"
          } else result[[paste0(contrast, ".status")]] <- "group absent"
        }
      }
    }
    result
  }) %>% bind_rows()
  tests$kruskal.q.bh <- p.adjust(tests$kruskal.p.raw, "BH")
  for (contrast in names(contrasts)) {
    tests[[paste0(contrast, ".q.across")]] <-
      p.adjust(tests[[paste0(contrast, ".q.within")]], "BH")
  }
  tests <- tests %>% mutate(
    transform = "log10(CPM + 1); mapped VF ORFs only",
    dunn.gate = "raw Kruskal-Wallis p < 0.05",
    correction = "BH within category, then BH across categories per contrast",
    dunn.tail = "dunn.test default one-sided P; no altp"
  )
  matrix <- counts %>% select(sample.id, vf.category, n) %>%
    pivot_wider(names_from = vf.category, values_from = n)
  list(counts = counts, count.matrix = matrix, normalized = normalized,
       omitted = omitted, cohort = cohort, unmapped = unmapped, tests = tests)
}
