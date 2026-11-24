###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   export_vf_category_analysis.R
###############################################################################


# write named audit tables without changing upstream inputs or historical sets
export.vf.category.tables <- function(tables, directory, stem) {
  dir.create(directory, recursive = TRUE, showWarnings = FALSE)
  for (name in names(tables)) {
    table <- tables[[name]] %>% mutate(
      vfdb_version = "VFDB_setA", orf_pool = "all_bacterial_prokka_cds"
    )
    write.csv(table, file.path(directory, paste0(
      stem, "_", gsub("\\.", "_", name), ".csv"
    )), row.names = FALSE)
  }
  invisible(NULL)
}


run.contig.category.analysis <- function(path, stats, reference, directory) {
  data <- read.contig.vf.categories(path, stats, reference)
  export.vf.category.tables(list(excluded.unknown.lifestyle = data$excluded),
                             directory, "contig_composition_VFDB_setA")
  for (mapped.only in c(FALSE, TRUE)) {
    for (group in c("category", "origin")) {
      for (separate in c(FALSE, TRUE)) {
        counts <- prepare.vf.composition(
          data$units, data$features, names(data$palette), group,
          separate, mapped.only
        )
        stem <- paste("contig_vf_composition", unique(counts$layout),
                       unique(counts$mapping), "VFDB_setA", sep = "_")
        export.vf.category.tables(list(counts = counts), directory, stem)
        plot <- create.vf.composition(counts, data$palette, separate)
        ggsave(file.path(directory, paste0(stem, ".svg")), plot,
               width = if (group == "origin") 17 else 11, height = 8)
        print(plot)
      }
    }
  }
  samples <- data$units %>% distinct(sample.id, category)
  counts <- data$features %>% count(sample.id, vf.category, name = "n")
  results <- compare.sample.vf.categories(samples, counts, names(data$palette))
  export.vf.category.tables(results, directory,
                             "contig_sample_vf_category_differential_VFDB_setA")
  print(knitr::kable(results$tests))
  invisible(NULL)
}
