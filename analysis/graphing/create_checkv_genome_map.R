###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   create_checkv_genome_map.R
###############################################################################


create.checkv.genome.map <- function(data, layout = c("separate_tracks",
                                                    "overlay")) {
  layout <- match.arg(layout)
  separate <- layout == "separate_tracks"
  panels <- data$selection %>% mutate(
    panel = paste0(category, " | rank ", selection.rank, " | ", genome.id,
                   " | ", format(genome.length, big.mark = ",", trim = TRUE),
                   " bp | VF ORFs: ", qualifying.vf.orfs),
    panel = factor(panel, levels = panel)
  )
  features <- data$annotations %>%
    left_join(panels %>% select(genome.id, panel), by = "genome.id") %>%
    mutate(
      y = if (separate) if_else(source.annotation.mode == "viral", 1, -1)
          else 0,
      midpoint = (start + end) / 2
    )
  viral <- features %>% filter(source.annotation.mode == "viral")
  vf <- features %>% filter(source.annotation.mode == "vf")
  backbones <- panels %>%
    tidyr::crossing(y = if (separate) c(1, -1) else 0)

  # draw the two prediction sources in order, using their original coordinates.
  plot <- ggplot() +
    geom_segment(data = backbones,
                 aes(x = 1, xend = genome.length, y = y, yend = y),
                 color = "black", linewidth = 0.3) +
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

  # reserve separate label bands and keep every label, including narrow ORFs.
  plot <- plot +
    ggrepel::geom_text_repel(
      data = viral %>% filter(ec.number != ""),
      aes(x = midpoint, y = y, label = annotation.id),
      nudge_y = 0.8, ylim = if (separate) c(1.4, 3.2) else c(0.4, 2.2),
      size = 2.6, seed = 123, max.overlaps = Inf,
      max.iter = 20000, max.time = 2, min.segment.length = 0,
      box.padding = 0.3, point.padding = 0.1, segment.color = "grey40"
    ) +
    ggrepel::geom_text_repel(
      data = vf,
      aes(x = midpoint, y = y, label = annotation.id),
      nudge_y = -0.8, ylim = if (separate) c(-3.2, -1.4) else c(-2.2, -0.4),
      size = 2.6, seed = 123, max.overlaps = Inf,
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
      limits = if (separate) c(-3.4, 3.4) else c(-2.4, 2.4),
      breaks = if (separate) c(-1, 1) else 0,
      labels = if (separate) c("VF calls", "Viral CDS") else "CDS"
    ) +
    scale_fill_manual(
      values = c("Viral ORF without EC" = "#BDBDBD",
                 "Viral ORF with EC" = "#3182BD", "VF call" = "#CB181D"),
      breaks = c("Viral ORF without EC", "Viral ORF with EC", "VF call"),
      drop = FALSE
    ) +
    labs(
      x = "Genome coordinate (bp)", y = NULL, fill = NULL,
      title = if (separate) "Top VF-bearing genomes: separate tracks"
              else "Top VF-bearing genomes: overlaid calls",
      subtitle = "VFDB set B; conservative trimming; three genomes per category",
      caption = paste(
        "Viral CDS and bacterial-mode VF calls come from separate Prokka runs.",
        "Overlaps are retained; arrows indicate strand. Labels resolve to",
        "the accompanying annotation tables."
      )
    ) +
    theme_bw() +
    theme(
      panel.grid.major.y = element_blank(), panel.grid.minor = element_blank(),
      legend.position = "bottom", strip.text = element_text(hjust = 0),
      plot.caption = element_text(hjust = 0),
      plot.margin = margin(t = 5.5, r = 24, b = 5.5, l = 5.5)
    )
  return(plot)
}
