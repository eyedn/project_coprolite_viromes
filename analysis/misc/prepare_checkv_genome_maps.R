###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   prepare_checkv_genome_maps.R
###############################################################################


prepare.checkv.genome.maps <- function(stats, metadata, features, viral.cds) {
  categories <- c("pal", "pre", "ind")
  keys <- c("checkv.filter", "genome.id")
  feature.columns <- c(
    keys, "feature_id", "start", "end", "strand", "product", "ec.number"
  )
  if (!all(c(keys, "category", "qualifying.vf.orfs", "vfdb_version",
             "orf_pool") %in% names(stats)) ||
      !all(c(keys, "genome.length") %in% names(metadata)) ||
      !all(feature.columns %in% names(viral.cds)) ||
      !all(c(feature.columns, "annotation", "vf.id", "vf_description",
             "full_seq_evalue", "full_seq_score", "full_seq_bias") %in%
           names(features))) {
    stop("Missing genome-map input columns")
  }
  if (anyNA(stats[c(keys, "category", "qualifying.vf.orfs",
                    "vfdb_version", "orf_pool")]) ||
      anyDuplicated(stats[keys]) || anyDuplicated(metadata[keys]) ||
      any(stats$checkv.filter != "conservative") ||
      any(metadata$checkv.filter != "conservative") ||
      any(stats$vfdb_version != "VFDB_setB") ||
      any(stats$orf_pool != "all_bacterial_prokka_cds") ||
      any(!stats$category %in% categories) ||
      !is.numeric(stats$qualifying.vf.orfs) ||
      any(!is.finite(stats$qualifying.vf.orfs)) ||
      any(stats$qualifying.vf.orfs < 0 |
          stats$qualifying.vf.orfs != floor(stats$qualifying.vf.orfs))) {
    stop("Invalid conservative full-pool VF genome statistics")
  }
  if (anyNA(metadata[c(keys, "genome.length")]) ||
      !is.numeric(metadata$genome.length) ||
      any(!is.finite(metadata$genome.length)) ||
      any(metadata$genome.length < 1 |
          metadata$genome.length != floor(metadata$genome.length)) ||
      nrow(anti_join(stats, metadata, by = keys)) > 0L) {
    stop("Invalid or missing genome lengths for maps")
  }

  # rank the full genome pool, independently of sample-prevalence eligibility.
  selection <- stats %>%
    mutate(category = factor(category, levels = categories)) %>%
    arrange(category, desc(qualifying.vf.orfs), genome.id, .locale = "C") %>%
    group_by(category) %>%
    slice_head(n = 3L) %>%
    mutate(selection.rank = row_number()) %>%
    ungroup() %>%
    left_join(metadata %>% select(all_of(keys), genome.length), by = keys) %>%
    transmute(category = as.character(category), selection.rank, genome.id,
              genome.length, qualifying.vf.orfs, checkv.filter,
              vfdb.version = vfdb_version)
  if (nrow(selection) != 9L ||
      !identical(as.integer(table(factor(selection$category,
                                        levels = categories))), rep(3L, 3))) {
    stop("Genome maps require exactly three genomes per category")
  }

  # validate source keys and geometry before restricting features to selections.
  vf <- features %>% filter(annotation == "vf")
  for (table in list(viral.cds, vf)) {
    if (anyNA(table[c(keys, "feature_id", "start", "end", "strand")]) ||
        any(!nzchar(table$feature_id)) ||
        anyDuplicated(table[c(keys, "feature_id")]) ||
        any(table$checkv.filter != "conservative") ||
        any(!table$strand %in% c("+", "-")) ||
        !is.numeric(table$start) || !is.numeric(table$end) ||
        any(!is.finite(table$start) | !is.finite(table$end)) ||
        nrow(anti_join(table, metadata, by = keys)) > 0L) {
      stop("Invalid genome-map feature keys, strands, or coordinates")
    }
    coordinates <- table %>%
      left_join(metadata %>% select(all_of(keys), genome.length), by = keys)
    if (any(coordinates$start < 1 | coordinates$end < coordinates$start |
            coordinates$end > coordinates$genome.length |
            coordinates$start != floor(coordinates$start) |
            coordinates$end != floor(coordinates$end))) {
      stop("Genome-map feature coordinates exceed genome bounds")
    }
  }
  scores <- vf[c("full_seq_evalue", "full_seq_score", "full_seq_bias")]
  if (anyNA(scores) || any(!is.finite(as.matrix(scores))) ||
      any(vf$full_seq_evalue > 1e-10 | vf$full_seq_score < 25 |
          vf$full_seq_score < 10 * vf$full_seq_bias) ||
      anyNA(vf$vf.id) || any(!nzchar(vf$vf.id))) {
    stop("Genome-map VF calls must satisfy the qualifying-hit thresholds")
  }

  # the supplemental source must recover every existing filtered viral feature.
  filtered.viral <- features %>% filter(annotation == "viral") %>%
    select(all_of(feature.columns))
  if (nrow(anti_join(filtered.viral, viral.cds,
                     by = feature.columns)) > 0L) {
    stop("Supplemental viral CDS disagree with filtered viral annotations")
  }
  vf.counts <- vf %>% count(across(all_of(keys)), name = "vf.count")
  coverage <- selection %>%
    left_join(vf.counts, by = keys) %>%
    left_join(viral.cds %>% count(across(all_of(keys)), name = "viral.count"),
              by = keys)
  if (any(replace_na(coverage$vf.count, 0L) != coverage$qualifying.vf.orfs)) {
    stop("Selected VF feature counts disagree with qualifying.vf.orfs")
  }
  if (anyNA(coverage$viral.count) || any(coverage$viral.count < 1L)) {
    stop("Missing complete viral-CDS input for a selected genome")
  }

  # never join feature IDs across annotation runs; overlapping calls stay rows.
  annotations <- bind_rows(
    viral.cds %>% select(all_of(feature.columns)) %>%
      mutate(source.annotation.mode = "viral", vf.id = "",
             vf.description = ""),
    vf %>% select(all_of(feature.columns), vf.id, vf_description) %>%
      rename(vf.description = vf_description) %>%
      mutate(source.annotation.mode = "vf")
  ) %>%
    inner_join(selection, by = keys) %>%
    mutate(across(c(product, ec.number, vf.id, vf.description),
                  ~ replace_na(as.character(.x), ""))) %>%
    arrange(match(category, categories), selection.rank,
            source.annotation.mode, start, end, feature_id, .locale = "C") %>%
    group_by(genome.id, source.annotation.mode) %>%
    mutate(annotation.id = paste0(
      category, selection.rank, ".",
      if_else(source.annotation.mode == "viral", "V", "F"),
      sprintf("%03d", row_number())
    )) %>%
    ungroup() %>%
    mutate(color.class = case_when(
      source.annotation.mode == "vf" ~ "VF call",
      ec.number != "" ~ "Viral ORF with EC",
      TRUE ~ "Viral ORF without EC"
    )) %>%
    select(category, selection.rank, genome.id, annotation.id,
           source.annotation.mode, source.feature.id = feature_id,
           start, end, strand, color.class, product, ec.number,
           vf.id, vf.description)
  if (anyDuplicated(annotations$annotation.id)) {
    stop("Genome-map annotation IDs are not unique")
  }
  return(list(selection = selection, annotations = annotations))
}
