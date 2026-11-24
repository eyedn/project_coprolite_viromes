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
                                    layout = c("stacked", "grouped")) {
  layout <- match.arg(layout)
  data <- summary[summary$mapping == mapping, ]
  caption <- paste(
    "Modern: 1,000 draws of 30 lytic + 5 temperate genomes; paleo fixed.",
    "Empty draws contribute zero; mean stacks may total less than one."
  )
  base <- list(
    scale_y_continuous(limits = c(0, 1), labels = scales::label_percent(),
                       oob = scales::squish,
                       expand = expansion(mult = c(0, .02))),
    labs(x = NULL, y = "Mean VF-category proportion",
         title = "Downsampled CheckV VF-category composition",
         subtitle = paste("VFDB set A; conservative;", mapping),
         caption = caption), theme_bw(),
    theme(legend.position = "bottom", panel.grid.minor = element_blank())
  )
  empty <- data %>% group_by(category, lifestyle) %>%
    summarise(empty = all(empty.draws == iterations), .groups = "drop") %>%
    filter(empty)
  if (layout == "stacked") {
    ggplot(data, aes(lifestyle, mean, fill = vf.category)) +
      geom_col(position = position_stack(reverse = TRUE), width = .75) +
      geom_text(data = empty, aes(lifestyle, .45, label = "No VF ORFs"),
                inherit.aes = FALSE, size = 3) +
      facet_grid(~ category, drop = FALSE) +
      scale_fill_manual(values = palette,
                         breaks = unique(as.character(data$vf.category)),
                         labels = function(x) stringr::str_wrap(x, 25)) +
      guides(fill = guide_legend(ncol = 4, byrow = TRUE)) + base +
      labs(fill = "VF category")
  } else {
    # fixed x offsets preserve group positions when paleo has no intervals
    data <- data %>% mutate(
      bar.x = as.numeric(vf.category) +
        (as.numeric(category) - 2) * .25
    )
    ggplot(data, aes(bar.x, mean, fill = category)) +
      geom_col(width = .23) +
      geom_errorbar(data = filter(data, category != "pal"),
                    aes(ymin = lower, ymax = upper), width = .12) +
      geom_text(data = filter(empty, category == "pal"),
                aes(x = 1, y = .9, label = "Paleo: no VF ORFs"),
                inherit.aes = FALSE, hjust = 0, size = 3) +
      facet_grid(lifestyle ~ ., drop = FALSE) +
      scale_x_continuous(
        breaks = sort(unique(as.numeric(data$vf.category))),
        labels = stringr::str_wrap(levels(droplevels(data$vf.category)), 18)
      ) +
      scale_fill_manual(values = c(pal = "#756BB1", pre = "#31A354",
                                    ind = "#3182BD"), drop = FALSE) + base +
      labs(fill = "Sample group") +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  }
}
