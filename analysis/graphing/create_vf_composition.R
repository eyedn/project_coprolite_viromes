###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   create_vf_composition.R
###############################################################################


create.vf.composition <- function(data, palette, separate = FALSE) {
  empty <- data %>% distinct(group, lifestyle, total.vf.orfs) %>%
    filter(total.vf.orfs == 0)
  plot <- ggplot(data, aes(x = if (separate) lifestyle else group,
                           y = proportion, fill = vf.category)) +
    geom_col(width = .75, position = position_stack(reverse = TRUE)) +
    geom_text(data = empty,
              aes(x = if (separate) lifestyle else group, y = .45,
                  label = "No VF\nORFs"), inherit.aes = FALSE, size = 2.7,
              angle = if (separate) 90 else 0) +
    scale_x_discrete(drop = FALSE) +
    scale_y_continuous(limits = c(0, 1), labels = scales::label_percent(),
                       oob = scales::squish,
                       expand = expansion(mult = c(0, .02))) +
    scale_fill_manual(values = palette,
                       breaks = levels(data$vf.category), drop = FALSE,
                       labels = function(x) stringr::str_wrap(x, 25)) +
    labs(x = NULL, y = "Proportion of qualifying VF ORFs", fill = "VF category",
         title = "Contig VF-category composition",
         subtitle = paste("VFDB set A;", unique(data$mapping))) +
    theme_bw() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
          legend.position = "bottom", panel.grid.minor = element_blank()) +
    guides(fill = guide_legend(ncol = 4, byrow = TRUE))
  if (separate) plot <- plot + facet_grid(~ group, drop = FALSE)
  plot
}


create.vf.downsampling <- function(summary, palette, mapping,
                                    layout = c("means", "means_ci",
                                               "means_ci_log10")) {
  layout <- match.arg(layout)
  data <- summary[summary$mapping == mapping, ]
  category.names <- names(palette)[names(palette) %in% data$vf.category]
  # percentages are calculated before the axis transforms means and endpoints
  data <- data %>% mutate(
    category = factor(category, c("pal", "pre", "ind")),
    lifestyle = factor(lifestyle, c("All", "Lytic", "Temperate")),
    vf.category = factor(vf.category, category.names),
    bar.x = as.numeric(vf.category) + (as.numeric(category) - 2) * .25,
    mean.percent = 100 * mean,
    lower.percent = 100 * lower, upper.percent = 100 * upper
  )
  empty.paleo <- data %>% filter(category == "pal") %>%
    group_by(lifestyle) %>%
    summarise(empty = all(empty.draws == iterations), .groups = "drop") %>%
    filter(empty)
  caption <- paste(
    "Bars: fixed paleo composition and arithmetic means of modern draws.",
    "Modern: 1,000 draws of 30 lytic + 5 temperate genomes per group.",
    "Empty denominators contribute zero."
  )
  plot <- ggplot(data, aes(bar.x, mean.percent, fill = category)) +
    geom_col(width = .23, position = "identity")
  if (layout != "means") {
    # fixed offsets keep modern intervals centered without a paleo interval
    plot <- plot + geom_errorbar(data = filter(data, category != "pal"),
      aes(ymin = lower.percent, ymax = upper.percent), width = .12)
    caption <- paste(caption,
      "95% CI: central 95% downsampling percentile intervals",
      "(2.5th-97.5th percentiles); paleo has no interval.")
  }
  transform <- "identity"
  breaks <- seq(0, 100, 25)
  y.title <- "Mean mapped VF-category percentage"
  if (layout == "means_ci_log10") {
    transform <- scales::trans_new(
      "log10_percent_plus_one", function(x) log10(x + 1),
      function(x) 10^x - 1, domain = c(0, Inf)
    )
    breaks <- c(0, 1, 5, 10, 25, 50, 100)
    y.title <- paste0(y.title, " [log10(percent + 1)]")
  }
  plot +
    geom_text(data = empty.paleo,
      aes(x = 2, y = 90, label = "Paleo: no mapped VF ORFs"),
      inherit.aes = FALSE, hjust = 0, size = 3) +
    facet_grid(lifestyle ~ ., drop = FALSE) +
    scale_x_continuous(breaks = seq_along(category.names),
      labels = stringr::str_wrap(category.names, 18)) +
    scale_y_continuous(limits = c(0, 100), trans = transform,
      breaks = breaks, labels = scales::label_number(suffix = "%"),
      expand = expansion(mult = c(0, .02))) +
    scale_fill_manual(values = c(pal = "#756BB1", pre = "#31A354",
                                  ind = "#3182BD"), drop = FALSE) +
    labs(x = NULL, y = y.title, fill = "Sample group",
      title = "Downsampled CheckV VF-category composition",
      subtitle = paste("VFDB set A; conservative;", mapping),
      caption = stringr::str_wrap(caption, 135)) +
    theme_bw() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
      legend.position = "bottom", panel.grid.minor = element_blank(),
      plot.caption = element_text(hjust = 0))
}
