###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   create_cat_voilins.R
###############################################################################
library(ggplot2)
library(reshape2)
library(RColorBrewer)
library(dplyr)
library(svglite)


# generate violin graph from temperate-to-virulent bootstrapping
create_cat_voilins <- function(data, ci_offset, file_name, plot_dir,
                               cats_order = NULL, plot.title = NULL,
                               x.title = NULL, y.title = NULL) {
  # reshape
  melted_data <- melt(data)
  if (ncol(melted_data) == 3) {
    colnames(melted_data) <- c("point", "cat", "value")
  } else if (ncol(melted_data) == 2) {
    colnames(melted_data) <- c("cat", "value")
  } else {
    stop("ncol(melted_data) not in (2,3); got:", ncol(melted_data))
  }
  melted_data$value <- as.numeric(melted_data$value)
  
  # determine category order
  if (is.null(cats_order)) {
    cats_order <- colnames(data)
  }
  melted_data$cat <- factor(melted_data$cat, levels = cats_order)
  
  # 95% CI per category
  ci_data <- as_tibble(melted_data) %>%
    group_by(cat) %>%
    summarise(
      median_value = median(value, na.rm = TRUE),
      ymin = quantile(value, 0.025, na.rm = TRUE),
      ymax = quantile(value, 0.975, na.rm = TRUE),
      .groups = "drop"
    )
  
  # make an x-position per category and offsets (vectorized)
  ci_data$x_pos <- as.numeric(ci_data$cat)
  if (length(ci_offset) == 1L) {
    ci_offset <- rep(ci_offset, nrow(ci_data))
  } else if (length(ci_offset) < nrow(ci_data)) {
    ci_offset <- rep(ci_offset, length.out = nrow(ci_data))
  }
  ci_data$x_lab_pos <- ci_data$x_pos + ci_offset
  # place the "95% CI" text near the first category's CI mid, like your original
  if (nrow(ci_data) >= 1) {
    first_mid <- (ci_data$ymin[1] + ci_data$ymax[1]) / 2
    first_x_text <- ci_data$x_lab_pos[1] + 0.1
  }
  
  # colors
  grey_border <- brewer.pal(9, "Greys")[8]
  grey_fill   <- brewer.pal(9, "Greys")[2]
  ci_color    <- brewer.pal(11, "RdBu")[10]
  
  # build plot
  violin <- ggplot(data = melted_data, aes(x = cat)) +
    geom_violin(
      aes(y = value, fill = cat),
      color = grey_border, linewidth = 1, trim = TRUE, width = 1
    ) +
    scale_fill_manual(values = rep(grey_fill, length(levels(melted_data$cat))), guide = "none") +
    stat_summary(
      aes(y = value), fun = median, geom = "point",
      fill = grey_border, color = grey_fill, stroke = 1, pch = 23, size = 5.5
    ) +
    # CI segments (vectorized)
    geom_segment(
      data = ci_data,
      aes(x = x_lab_pos, xend = x_lab_pos, y = ymin, yend = ymax),
      inherit.aes = FALSE, linewidth = 2, color = ci_color
    ) +
    # Single "95% CI" label like your original
    {
      if (nrow(ci_data) >= 1 & ncol(melted_data) == 3) {
        annotate(
          "text", x = first_x_text, y = first_mid,
          label = "95% CI", angle = -90, size = 8, color = ci_color
        )
      } else NULL
    } +
    labs(title = plot.title, x = x.title, y = y.title) +
    theme_bw() +
    theme(
      plot.margin = margin(20, 5, 20, 20, "points"),
      axis.text.y  = element_text(size = 14, color = "black", face = "bold", hjust = -0.5),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      axis.ticks.x = element_blank(),
      axis.ticks.y = element_line(linewidth = 2, color = "black"),
      panel.border = element_rect(color = "black", size = 2, fill = NA)
    )
  
  # save (same helper as your original)
  file_name <- append_time_to_filename(file_name)
  ggsave(
    filename = paste0(plot_dir, "/", file_name, ".svg"),
    plot = violin, height = 7, width = 7
  )
  
  return(list(violin, ci_data))
}
