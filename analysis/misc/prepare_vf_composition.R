###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   prepare_vf_composition.R
###############################################################################


# pool qualifying ORFs across recognized lifestyles without sample exclusions
prepare.vf.composition <- function(units, vf, category.names,
                                    group = c("category", "origin"),
                                    separate = FALSE, mapped.only = FALSE) {
  group <- match.arg(group)
  origin.order <- c("AUT", "AWC", "BMS", "ZAF", "ZAP", "FJI", "MDG",
                    "MEX", "NPL", "PER", "TZA", "CHN", "DNK", "ESP", "USA")
  group.order <- if (group == "category") c("pal", "pre", "ind") else {
    c(origin.order, sort(setdiff(unique(units$origin), origin.order)))
  }
  categories <- if (mapped.only) {
    setdiff(category.names, "Unmapped VF category")
  } else category.names
  layout.name <- paste0(group, if (separate) "_lifestyle" else "_pooled")
  population <- units %>%
    filter(lifestyle %in% c("lytic", "temperate")) %>%
    transmute(sample.id, contig.id, group = .data[[group]],
              lifestyle = if (separate) lifestyle else "all")
  counts <- population %>%
    inner_join(vf %>% select(sample.id, contig.id, vf.category),
               by = c("sample.id", "contig.id"),
               relationship = "one-to-many") %>%
    filter(vf.category %in% categories) %>%
    count(group, lifestyle, vf.category, name = "category.orfs")
  crossing(group = group.order,
           lifestyle = if (separate) c("lytic", "temperate") else "all",
           vf.category = categories) %>%
    left_join(counts, by = c("group", "lifestyle", "vf.category")) %>%
    mutate(category.orfs = replace_na(category.orfs, 0L)) %>%
    group_by(group, lifestyle) %>%
    mutate(total.vf.orfs = sum(category.orfs),
           proportion = category.orfs / pmax(total.vf.orfs, 1L)) %>%
    ungroup() %>%
    mutate(group = factor(group, levels = group.order),
           lifestyle = factor(
             lifestyle,
             levels = if (separate) c("lytic", "temperate") else "all",
             labels = if (separate) c("Lytic", "Temperate") else "All"
           ),
           vf.category = factor(vf.category, levels = categories),
           mapping = if (mapped.only) "mapped_only" else "mapped_inclusive",
           layout = layout.name)
}
