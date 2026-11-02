# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# ___
# make_vf_prevalence_plot.R
# ______________________________________________________________________________
# Summaries and layers use exactly the same finite genome observations.
make.vf.prevalence.plot <- function(data, lifestyle.column, lifestyle.label,
                                     facet.categories = TRUE) {
  data <- data %>% filter(is.finite(vf.orf.prevalence))
  if (!facet.categories) {
    data <- data %>% mutate(category = factor(category,
                                             levels = c("pal", "pre", "ind")))
  }
  group.columns <- unique(c("vfdb.version", "category", lifestyle.column))
  mean.data <- data %>%
    group_by(across(all_of(group.columns))) %>%
    summarise(mean.prevalence = mean(vf.orf.prevalence),
              n = n(), .groups = "drop") %>%
    mutate(lifestyle = .data[[lifestyle.column]])

  plot <- ggplot(
    data,
    aes(x = .data[[lifestyle.column]], y = vf.orf.prevalence,
        fill = .data[[lifestyle.column]])
  ) +
    geom_violin(alpha = 0.35) +
    geom_boxplot(fill = "white", color = "black") +
    geom_text(
      data = mean.data,
      aes(x = lifestyle, y = mean.prevalence,
          label = paste0("Mean = ", sprintf("%.3f", mean.prevalence),
                         "; n = ", n)),
      inherit.aes = FALSE, vjust = -0.7, size = 3
    ) +
    labs(
      x = lifestyle.label,
      y = "Qualifying VFDB-hit ORFs / all Prokka ORFs",
      fill = lifestyle.label,
      title = paste("Complete-genome VF prevalence by", lifestyle.label,
                    "(conservative trimming)")
    ) +
    theme_bw()
  if (facet.categories) {
    plot <- plot + facet_grid(category ~ vfdb.version)
  }
  return(plot)
}
