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
                                    layout = c("stacked", "violin", "example"),
                                    iterations = NULL) {
  layout <- match.arg(layout)
  data <- summary[summary$mapping == mapping, ]
  if (layout != "stacked" && is.null(iterations)) {
    stop("Iteration-level proportions are required for this layout")
  }
  caption <- paste(
    "Modern: 1,000 draws of 30 lytic + 5 temperate genomes; paleo fixed.",
    "Empty draws contribute zero; mean stacks may total less than one."
  )
  subtitle <- paste("VFDB set A; conservative;", mapping)
  title <- "Downsampled CheckV VF-category composition"
  y.title <- "Mean mapped VF-category proportion"
  if (layout == "example") {
    data <- iterations %>% filter(.data$mapping == .env$mapping,
                                   iteration == 1L) %>%
      mutate(mean = proportion, empty.draws = as.integer(total.vf.orfs == 0L),
             iterations = 1L)
    title <- "One iteration of CheckV genome downsampling"
    subtitle <- paste(subtitle, "iteration 1; seed 123", sep = "; ")
    y.title <- "Mapped VF-category proportion"
    caption <- paste(
      "One draw of 30 lytic + 5 temperate genomes per modern group.",
      "All paleo genomes are fixed; All pools the selected genomes."
    )
  }
  base <- list(
    scale_y_continuous(limits = c(0, 1), labels = scales::label_percent(),
                       oob = scales::squish,
                       expand = expansion(mult = c(0, .02))),
    labs(x = NULL, y = y.title, title = title, subtitle = subtitle,
         caption = stringr::str_wrap(caption, 135)),
    theme_bw(),
    theme(legend.position = "bottom", panel.grid.minor = element_blank(),
          plot.caption = element_text(hjust = 0))
  )
  if (layout %in% c("stacked", "example")) {
    empty <- data %>% group_by(category, lifestyle) %>%
      summarise(empty = all(empty.draws == iterations), .groups = "drop") %>%
      filter(empty)
    return(ggplot(data, aes(lifestyle, mean, fill = vf.category)) +
      geom_col(position = position_stack(reverse = TRUE), width = .75) +
      geom_text(data = empty, aes(lifestyle, .45, label = "No mapped VF ORFs"),
                inherit.aes = FALSE, size = 3) +
      facet_grid(~ category, drop = FALSE) +
      scale_fill_manual(values = palette,
                         breaks = unique(as.character(data$vf.category)),
                         labels = function(x) stringr::str_wrap(x, 25)) +
      guides(fill = guide_legend(ncol = 4, byrow = TRUE)) + base +
      labs(fill = "VF category"))
  }

  # modern distributions use every draw, including zero-denominator draws
  draws <- iterations %>% filter(.data$mapping == .env$mapping) %>%
    mutate(bar.x = as.numeric(vf.category) + (as.numeric(category) - 2) * .25)
  points <- draws %>% group_by(category, lifestyle, vf.category, bar.x) %>%
    summarise(median = median(proportion), lower = quantile(proportion, .025),
              upper = quantile(proportion, .975),
              empty = all(total.vf.orfs == 0),
              .groups = "drop")
  varying <- draws %>% filter(category != "pal") %>%
    group_by(category, lifestyle, vf.category) %>%
    filter(n_distinct(proportion) > 1L) %>% ungroup()
  empty.paleo <- points %>% filter(category == "pal") %>%
    group_by(lifestyle) %>% summarise(empty = all(empty), .groups = "drop") %>%
    filter(empty)
  grey.border <- RColorBrewer::brewer.pal(9, "Greys")[8]
  grey.fill <- RColorBrewer::brewer.pal(9, "Greys")[2]
  ci.color <- RColorBrewer::brewer.pal(11, "RdBu")[10]
  caption <- paste(
    "Within each VF category: pal, pre, ind (left to right).",
    "Gray violins show modern iteration proportions; diamonds mark medians;",
    "blue lines show 2.5th-97.5th percentiles, including zero draws.",
    "Paleo is a fixed observed point without an interval.",
    "Constant modern distributions are shown as points."
  )
  ggplot(draws, aes(bar.x, proportion)) +
    geom_violin(data = varying,
      aes(group = interaction(vf.category, category)),
      fill = grey.fill, color = grey.border, linewidth = .7,
      width = .22, position = "identity", trim = TRUE) +
    geom_point(data = points, aes(bar.x, median),
      shape = 23, fill = grey.border, color = grey.fill,
      stroke = .8, size = 3) +
    geom_segment(data = filter(points, category != "pal"),
      aes(x = bar.x + .07, xend = bar.x + .07, y = lower, yend = upper),
      inherit.aes = FALSE, color = ci.color, linewidth = 1.1) +
    geom_text(data = empty.paleo,
      aes(x = 1, y = .93, label = "Paleo: no mapped VF ORFs"),
      inherit.aes = FALSE, hjust = 0, size = 3) +
    facet_grid(lifestyle ~ ., drop = FALSE) +
    scale_x_continuous(
      breaks = sort(unique(as.numeric(draws$vf.category))),
      labels = stringr::str_wrap(levels(droplevels(draws$vf.category)), 18)
    ) + base +
    labs(y = "Mapped VF-category proportion",
         title = "Distribution of downsampled VF-category proportions",
         caption = stringr::str_wrap(caption, 135)) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1, color = "black"),
          axis.text.y = element_text(face = "bold", color = "black"),
          axis.ticks.x = element_blank(), panel.grid.major = element_blank(),
          panel.border = element_rect(color = "black", linewidth = 1.2,
                                       fill = NA))
}
