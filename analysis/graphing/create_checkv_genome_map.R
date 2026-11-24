###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   create_checkv_genome_map.R
###############################################################################


create.checkv.genome.map <- function(data, layout = c("separate_tracks",
                                                    "overlay")) {
  layout <- match.arg(layout)
  separate <- layout == "separate_tracks"
  has.checkv <- isTRUE(data$has.checkv)
  checkv.y <- if (separate) 4 else 0
  viral.y <- if (separate) if (has.checkv) 0 else 1 else 0
  vf.y <- if (separate) if (has.checkv) -4 else -1 else 0
  panels <- data$selection %>% mutate(
    panel = paste0(category, " | rank ", selection.rank, " | ", genome.id,
                   " | ", format(genome.length, big.mark = ",", trim = TRUE),
                   " bp | mapped VF ORFs: ", mapped.vf.orfs,
                   " | total VF ORFs: ", qualifying.vf.orfs),
    panel = factor(panel, levels = panel)
  )
  features <- data$annotations %>%
    filter(plotted.feature) %>%
    left_join(panels %>% select(genome.id, panel), by = "genome.id") %>%
    mutate(
      y = case_when(source.annotation.mode == "checkv" ~ checkv.y,
                    source.annotation.mode == "viral" ~ viral.y,
                    TRUE ~ vf.y),
      midpoint = (start + end) / 2
    )
  checkv <- features %>% filter(source.annotation.mode == "checkv")
  viral <- features %>% filter(source.annotation.mode == "viral")
  vf <- features %>% filter(source.annotation.mode == "vf")
  backbones <- panels %>%
    tidyr::crossing(y = if (separate) {
      if (has.checkv) c(checkv.y, viral.y, vf.y) else c(viral.y, vf.y)
    } else 0)

  # draw CheckV, viral, then VF calls at their original coordinates
  plot <- ggplot() +
    geom_segment(data = backbones,
                 aes(x = 1, xend = genome.length, y = y, yend = y),
                 color = "black", linewidth = 0.3) +
    gggenes::geom_gene_arrow(
      data = checkv,
      aes(xmin = start, xmax = end, y = y, forward = strand == "+",
          fill = color.class),
      color = "black", linewidth = 0.2,
      arrowhead_width = grid::unit(1.6, "mm"),
      arrowhead_height = grid::unit(2.4, "mm"),
      arrow_body_height = grid::unit(1.7, "mm")
    ) +
    gggenes::geom_gene_arrow(
      data = viral,
      aes(xmin = start, xmax = end, y = y, forward = strand == "+",
          fill = color.class),
      color = "black", linewidth = 0.2,
      arrowhead_width = grid::unit(1.6, "mm"),
      arrowhead_height = grid::unit(2.4, "mm"),
      arrow_body_height = grid::unit(1.7, "mm")
    ) +
    gggenes::geom_gene_arrow(
      data = vf,
      aes(xmin = start, xmax = end, y = y, forward = strand == "+",
          fill = color.class),
      color = "black", linewidth = 0.2,
      arrowhead_width = grid::unit(1.6, "mm"),
      arrowhead_height = grid::unit(2.4, "mm"),
      arrow_body_height = grid::unit(1.7, "mm")
    )

  # reserve separate label bands and keep every label, including narrow ORFs
  plot <- plot +
    ggrepel::geom_label_repel(
      data = checkv,
      aes(x = midpoint, y = y, label = plot.label),
      nudge_y = if (separate) {
        rep(c(1.5, 3.5, 5.5, 7.5), length.out = nrow(checkv))
      } else 1.5,
      ylim = if (separate) c(5, 13) else c(2.7, 6),
      size = 2.3, seed = 123, max.overlaps = Inf,
      force_pull = 0, max.iter = 50000, max.time = 5,
      fill = "white", label.size = 0,
      label.padding = grid::unit(0.08, "lines"),
      label.r = grid::unit(0, "lines"), min.segment.length = 0,
      box.padding = 0.25, point.padding = 0.1, segment.color = "grey40"
    ) +
    ggrepel::geom_text_repel(
      data = viral %>% filter(ec.number != ""),
      aes(x = midpoint, y = y, label = plot.label),
      nudge_y = 0.8, ylim = if (separate) {
        if (has.checkv) c(1, 3) else c(1.4, 3.2)
      } else c(0.4, 2.2),
      size = 2.6, seed = 123, max.overlaps = Inf,
      max.iter = 20000, max.time = 2, min.segment.length = 0,
      box.padding = 0.3, point.padding = 0.1, segment.color = "grey40"
    ) +
    ggrepel::geom_text_repel(
      data = vf,
      aes(x = midpoint, y = y, label = plot.label),
      nudge_y = -0.8, ylim = if (separate) {
        if (has.checkv) c(-8, -5) else c(-3.2, -1.4)
      } else c(-3.4, -0.4),
      size = 2.3, seed = 123, max.overlaps = Inf,
      max.iter = 20000, max.time = 2, min.segment.length = 0,
      box.padding = 0.3, point.padding = 0.1, segment.color = "grey40"
    ) +
    facet_wrap(~ panel, ncol = 1, scales = "free_x") +
    scale_x_continuous(
      expand = expansion(mult = 0), labels = scales::label_comma(),
      breaks = function(limits) {
        ticks <- scales::breaks_pretty(n = 4)(limits)
        margin <- diff(limits) * 0.08
        c(limits[1], ticks[ticks > limits[1] + margin &
                            ticks < limits[2] - margin], limits[2])
      }
    ) +
    scale_y_continuous(
      limits = if (has.checkv) {
        if (separate) c(-8.4, 13.4) else c(-3.6, 6.2)
      } else if (separate) c(-3.4, 3.4) else c(-3.6, 2.4),
      breaks = if (separate) {
        if (has.checkv) c(vf.y, viral.y, checkv.y) else c(vf.y, viral.y)
      } else 0,
      labels = if (separate) {
        if (has.checkv) c("VF calls", "Viral EC ORFs", "CheckV HMM hits")
        else c("VF calls", "Viral EC ORFs")
      } else "ORFs"
    ) +
    scale_fill_manual(
      values = c(if (has.checkv) c("CheckV HMM-hit ORF" = "#756BB1"),
                 "Viral ORF with EC" = "#3182BD",
                 "Qualifying VF ORF" = "#DE2D26"),
      breaks = c(if (has.checkv) "CheckV HMM-hit ORF",
                 "Viral ORF with EC", "Qualifying VF ORF"),
      drop = FALSE,
      labels = function(x) stringr::str_wrap(x, 28)
    ) +
    labs(
      x = "Genome coordinate (bp)", y = NULL, fill = NULL,
      title = if (separate) "Top VF-bearing genomes: separate tracks"
              else "Top VF-bearing genomes: overlaid calls",
      subtitle = paste(paste0(gsub("VFDB_set", "VFDB set ",
                               unique(data$selection$vfdb.version)),
                         "; conservative trimming;"),
                       "three genomes per category; ranked by",
                       if (data$selection.by == "mapped") "mapped VF count"
                       else "total VF count"),
      caption = stringr::str_wrap(paste(
        if (has.checkv) paste(
          "CheckV HMM hits are purple; labels show HMM description and category."
        ),
        "Viral CDS and bacterial-mode VF calls come from separate Prokka runs.",
        "Only EC-bearing viral CDS are drawn (blue, annotation-ID labels).",
        "All qualifying VF calls are red, with annotation ID, VF name and category.",
        "Overlaps and strands are retained;",
        "complete annotations accompany maps."
      ), 145)
    ) +
    theme_bw() +
    theme(
      panel.grid.major.y = element_blank(), panel.grid.minor = element_blank(),
      legend.position = "bottom", strip.text = element_text(hjust = 0),
      plot.caption = element_text(hjust = 0),
      plot.margin = margin(t = 5.5, r = 24, b = 5.5, l = 5.5)
    ) + guides(fill = guide_legend(ncol = 4, byrow = TRUE))
  return(plot)
}
