###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   downsample_checkv_vf.R
###############################################################################


# seed locally so earlier report sections cannot alter the genome selections
downsample.checkv.vf <- function(stats, vf, category.names,
                                  iterations = 1000L, seed = 123L,
                                  lytic = 30L, temperate = 5L,
                                  paleo.lytic = 30L, paleo.temperate = 5L,
                                  mapped.only = FALSE) {
  if (iterations < 1L || iterations != as.integer(iterations)) {
    stop("Iterations must be a positive integer")
  }
  # validate all calls, including unknown lifestyles, before selecting genomes
  prepare.checkv.vf.composition(stats, vf, category.names)
  old.seed <- if (exists(".Random.seed", .GlobalEnv)) {
    get(".Random.seed", .GlobalEnv)
  } else NULL
  on.exit({
    if (is.null(old.seed)) {
      rm(".Random.seed", envir = .GlobalEnv)
    } else assign(".Random.seed", old.seed, .GlobalEnv)
  }, add = TRUE)
  set.seed(seed)
  genomes <- stats %>%
    mutate(lifestyle = normalize.checkv.lifestyle(checkv.lifestyle)) %>%
    filter(lifestyle %in% c("lytic", "temperate")) %>%
    arrange(category, lifestyle, genome.id)
  selections <- list()
  for (group in c("pal", "pre", "ind")) {
    for (life in c("lytic", "temperate")) {
      pool <- genomes %>% filter(category == group, lifestyle == life)
      size <- if (life == "lytic") lytic else temperate
      if (group == "pal") {
        expected <- if (life == "lytic") paleo.lytic else paleo.temperate
        if (nrow(pool) != expected) {
          stop("Paleo ", life, " must contain exactly ", expected, " genomes")
        }
        size <- nrow(pool)
      } else if (nrow(pool) < size) {
        stop(group, " ", life, " cannot supply ", size, " genomes")
      }
      for (iteration in seq_len(iterations)) {
        ids <- if (group == "pal") seq_len(size) else {
          sample.int(nrow(pool), size, replace = FALSE)
        }
        selections[[length(selections) + 1L]] <- pool[ids, ] %>%
          transmute(iteration, category, lifestyle, genome.id, checkv.filter)
      }
    }
  }
  selections <- bind_rows(selections)
  selected <- bind_rows(selections, mutate(selections, lifestyle = "all"))
  counts <- selected %>%
    inner_join(vf %>% select(checkv.filter, genome.id, vf.category),
               by = c("checkv.filter", "genome.id"),
               relationship = "many-to-many") %>%
    count(iteration, category, lifestyle, vf.category, name = "category.orfs")
  results <- list()
  mappings <- if (mapped.only) "mapped_only" else {
    c("mapped_inclusive", "mapped_only")
  }
  for (mapping in mappings) {
    categories <- if (mapping == "mapped_only") {
      setdiff(category.names, "Unmapped VF category")
    } else category.names
    results[[mapping]] <- crossing(
      iteration = seq_len(iterations), category = c("pal", "pre", "ind"),
      lifestyle = c("all", "lytic", "temperate"), vf.category = categories
    ) %>% left_join(counts,
      by = c("iteration", "category", "lifestyle", "vf.category")) %>%
      mutate(category.orfs = replace_na(category.orfs, 0L)) %>%
      group_by(iteration, category, lifestyle) %>%
      mutate(total.vf.orfs = sum(category.orfs),
             proportion = category.orfs / pmax(total.vf.orfs, 1L)) %>%
      ungroup() %>% mutate(mapping = mapping)
  }
  draws <- bind_rows(results) %>%
    mutate(category = factor(category, c("pal", "pre", "ind")),
           lifestyle = factor(lifestyle, c("all", "lytic", "temperate"),
                              c("All", "Lytic", "Temperate")),
           vf.category = factor(vf.category, category.names))
  summary <- draws %>% group_by(mapping, category, lifestyle, vf.category) %>%
    summarise(mean = mean(proportion), median = median(proportion),
              lower = quantile(proportion, .025),
              upper = quantile(proportion, .975),
              mean.category.orfs = mean(category.orfs),
              empty.draws = sum(total.vf.orfs == 0), iterations = n(),
              .groups = "drop")
  list(selections = selections, iterations = draws, summary = summary,
       example = filter(draws, iteration == 1L))
}
