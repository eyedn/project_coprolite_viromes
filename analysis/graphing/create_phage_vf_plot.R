###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   create_phage_vf_plot.R
###############################################################################
# Create one descriptive phage-level lifestyle-by-VFDB plot.
create.phage.vf.plot <- function(data, statistic, facet.variable,
                                 plot.title, y.title) {
  category.labels <- c(
    pal = "Paleofecal/coprolite",
    pre = "Modern non-industrial",
    ind = "Modern industrial"
  )
  facet.labeller <- if (facet.variable == "category") {
    as_labeller(category.labels)
  } else {
    label_value
  }

  plot <- ggplot(
    data,
    aes(x = lifestyle, y = .data[[statistic]])
  ) +
    geom_violin(
      fill = "grey85", color = "grey30", trim = TRUE, na.rm = TRUE
    ) +
    geom_boxplot(
      width = 0.16, fill = "grey65", color = "black",
      outlier.shape = NA, na.rm = TRUE
    ) +
    geom_point(
      position = position_jitter(width = 0.08, height = 0, seed = 123),
      shape = 21, fill = "grey95", color = "black", alpha = 0.55,
      size = 1.4, na.rm = TRUE
    ) +
    facet_wrap(
      vars(.data[[facet.variable]]),
      scales = "fixed",
      labeller = facet.labeller
    ) +
    scale_y_continuous(limits = c(0, 1)) +
    labs(
      title = plot.title,
      x = "Predicted phage lifestyle",
      y = y.title
    ) +
    theme_bw() +
    theme(
      panel.grid.minor = element_blank(),
      legend.position = "none"
    )

  return(plot)
}
