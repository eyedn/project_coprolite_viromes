###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   prepare_checkv_genome_maps.R
###############################################################################


prepare.checkv.genome.maps <- function(stats, metadata, features, viral.cds,
                                      vf.reference, selection = NULL,
                                      checkv.features = NULL,
                                      selection.by = c("total", "mapped"),
                                      checkv.hmms = NULL) {
  selection.by <- match.arg(selection.by)
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
      any(stats$vfdb_version != "VFDB_setA") ||
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

  # rank independently of sample eligibility; mapped ties use genome IDs.
  mapped <- prepare.checkv.vf.categories(features, vf.reference)
  mapped.counts <- mapped$features %>%
    filter(vf.category != "Unmapped VF category") %>%
    count(across(all_of(keys)), name = "mapped.vf.orfs")
  candidates <- stats %>% left_join(mapped.counts, by = keys) %>%
    mutate(mapped.vf.orfs = replace_na(mapped.vf.orfs, 0L))
  if (is.null(selection)) {
    selection <- candidates %>%
      filter(selection.by == "total" | mapped.vf.orfs > 0L) %>%
      mutate(category = factor(category, levels = categories),
             ranking.count = if (selection.by == "mapped") mapped.vf.orfs
                             else qualifying.vf.orfs) %>%
      arrange(category, desc(ranking.count), genome.id, .locale = "C") %>%
      group_by(category) %>% slice_head(n = 3L) %>%
      mutate(selection.rank = row_number()) %>% ungroup() %>%
      select(all_of(keys), selection.rank)
  }
  if (!all(c(keys, "selection.rank") %in% names(selection)) ||
      anyNA(selection[c(keys, "selection.rank")]) ||
      anyDuplicated(selection[keys]) ||
      nrow(anti_join(selection, stats, by = keys)) > 0L) {
    stop("Invalid explicit genome-map selection")
  }
  selection <- selection %>% select(all_of(keys), selection.rank) %>%
    left_join(candidates, by = keys) %>%
    left_join(metadata %>% select(all_of(keys), genome.length), by = keys) %>%
    transmute(category = as.character(category), selection.rank, genome.id,
              genome.length, qualifying.vf.orfs, mapped.vf.orfs, checkv.filter,
              vfdb.version = vfdb_version) %>%
    arrange(match(category, categories), selection.rank)
  if (nrow(selection) != 9L ||
      !identical(as.integer(table(factor(selection$category,
                                        levels = categories))), rep(3L, 3)) ||
      anyDuplicated(selection[c("category", "selection.rank")]) ||
      any(!selection$selection.rank %in% 1:3)) {
    stop("Genome maps require exactly three genomes per category")
  }

  # validate source keys and geometry before restricting features to selections
  vf <- mapped$features
  vf$vf.name <- if ("VF_Name" %in% names(vf.reference)) {
    trimws(as.character(vf.reference$VF_Name[
      match(vf$vf.id, trimws(as.character(vf.reference$VFID)))
    ]))
  } else {
    rep("", nrow(vf))
  }
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

  # the supplemental source must recover every existing filtered viral feature
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

  # preserve the CheckV source columns; only nonblank database hits are drawn.
  checkv <- NULL
  if (!is.null(checkv.features)) {
    required <- c("contig_id", "gene_num", "start", "end", "strand", "gc",
                  "hmm_cat", "hmm_db", "hmm_name", "evalue", "score")
    if (!all(required %in% names(checkv.features))) {
      stop("Missing CheckV gene feature columns")
    }
    if (anyNA(checkv.features[c("contig_id", "gene_num")]) ||
        anyDuplicated(checkv.features[c("contig_id", "gene_num")]) ||
        any(!checkv.features$contig_id %in% selection$genome.id)) {
      stop("Invalid CheckV genome/gene-number keys or genome membership")
    }
    checkv <- checkv.features %>%
      filter(!is.na(hmm_db), nzchar(trimws(hmm_db)), trimws(hmm_db) != "NA")
    if (anyNA(checkv[c("contig_id", "gene_num", "strand")]) ||
        anyDuplicated(checkv[c("contig_id", "gene_num")]) ||
        any(!checkv$contig_id %in% selection$genome.id) ||
        !is.numeric(checkv$gene_num) ||
        any(!is.finite(checkv$gene_num) | checkv$gene_num < 1 |
            checkv$gene_num != floor(checkv$gene_num)) ||
        any(!checkv$strand %in% c(1, -1))) {
      stop("Invalid CheckV genome/gene-number keys or strand")
    }
    numeric.columns <- c("start", "end", "evalue", "score")
    if (nrow(checkv) > 0L &&
        (!all(vapply(checkv[numeric.columns], is.numeric, logical(1))) ||
         anyNA(checkv[numeric.columns]) ||
         any(!is.finite(as.matrix(checkv[numeric.columns]))) ||
         any(checkv$evalue < 0))) {
      stop("Invalid CheckV numeric coordinates, scores, or E-values")
    }
    # join descriptions once per HMM key, preserving every source hit
    if (is.null(checkv.hmms) ||
        !all(c("database", "hmm", "desc", "category") %in%
             names(checkv.hmms))) {
      stop("Missing CheckV HMM lookup columns")
    }
    lookup <- checkv.hmms %>%
      select(database, hmm, desc, hmm.category = category) %>% distinct()
    if (anyNA(lookup[c("database", "hmm", "hmm.category")]) ||
        any(!lookup$hmm.category %in% c("viral", "microbial"))) {
      stop("Invalid CheckV HMM lookup keys or categories")
    }
    if (anyDuplicated(lookup[c("database", "hmm")])) {
      stop("Conflicting HMM lookup keys (database, hmm)")
    }
    checkv <- checkv %>% left_join(
      lookup, by = c("hmm_db" = "database", "hmm_name" = "hmm"),
      relationship = "many-to-one"
    )
    if (anyNA(checkv$hmm.category)) {
      stop("CheckV HMM hits are missing lookup categories")
    }
    checkv <- checkv %>%
      rename(genome.id = contig_id) %>%
      left_join(selection %>% select(genome.id, genome.length),
                by = "genome.id")
    if (any(checkv$start < 1 | checkv$end < checkv$start |
            checkv$end > checkv$genome.length |
            checkv$start != floor(checkv$start) |
            checkv$end != floor(checkv$end))) {
      stop("CheckV coordinates exceed selected genome bounds")
    }
    checkv <- checkv %>% select(-genome.length) %>%
      mutate(checkv.filter = "conservative",
             feature_id = paste0("checkv_gene_", gene_num),
             strand = if_else(strand == 1, "+", "-"),
             source.annotation.mode = "checkv", product = "", ec.number = "",
             vf.id = "", vf.description = "", vf.category = "")
  }

  # never join feature IDs across annotation runs; overlapping calls stay rows
  annotations <- bind_rows(
    viral.cds %>% select(all_of(feature.columns)) %>%
      mutate(source.annotation.mode = "viral", vf.id = "",
             vf.description = "", vf.category = "", desc = NA_character_,
             hmm.category = NA_character_, hmm_name = NA_character_),
    vf %>% select(all_of(feature.columns), vf.id, vf_description,
                  vf.name, vf.category) %>%
      rename(vf.description = vf_description) %>%
      mutate(source.annotation.mode = "vf"),
    checkv
  ) %>%
    inner_join(selection, by = keys) %>%
    mutate(across(c(product, ec.number, vf.id, vf.name, vf.description),
                  ~ replace_na(as.character(.x), ""))) %>%
    arrange(match(category, categories), selection.rank,
            source.annotation.mode, start, end, feature_id, .locale = "C") %>%
    group_by(genome.id, source.annotation.mode) %>%
    mutate(annotation.id = paste0(
      category, selection.rank, ".",
      case_when(source.annotation.mode == "checkv" ~ "C",
                source.annotation.mode == "viral" ~ "V", TRUE ~ "F"),
      sprintf("%03d", row_number())
    )) %>%
    ungroup() %>%
    mutate(plotted.feature = source.annotation.mode %in% c("checkv", "vf") |
             nzchar(trimws(ec.number)),
           color.class = case_when(
      source.annotation.mode == "checkv" ~ "CheckV HMM-hit ORF",
      source.annotation.mode == "vf" ~ "Qualifying VF ORF",
      nzchar(trimws(ec.number)) ~ "Viral ORF with EC",
      TRUE ~ "Viral ORF without EC"
    ), plot.label = case_when(
      source.annotation.mode == "checkv" ~ paste0(
        stringr::str_replace_all(stringr::str_wrap(if_else(
          is.na(desc) | !nzchar(trimws(desc)),
          paste(hmm_name, "(no descriptive label)"), desc
        ), 28), "(\\S{28})(?=\\S)", "\\1\n"), "\n", hmm.category
      ),
      source.annotation.mode == "viral" ~ paste0(
        annotation.id,
        if_else(nzchar(trimws(product)),
                paste0("\n", stringr::str_wrap(product, 28)), ""),
        "\nEC ", ec.number
      ),
      TRUE ~ paste0(
        annotation.id,
        if_else(nzchar(trimws(vf.name)),
                paste0("\n", stringr::str_wrap(vf.name, 28)), ""),
        "\n", stringr::str_wrap(vf.category, 24)
      )
    )) %>%
    select(category, selection.rank, genome.id, annotation.id,
           source.annotation.mode, source.feature.id = feature_id,
           start, end, strand, color.class, product, ec.number,
           vf.id, vf.name, vf.description, vf.category, plotted.feature,
           plot.label, desc, hmm.category,
           any_of(c("gene_num", "hmm_cat", "hmm_db", "hmm_name", "evalue",
                    "score", "gc")))
  if (anyDuplicated(annotations$annotation.id)) {
    stop("Genome-map annotation IDs are not unique")
  }
  return(list(selection = selection, annotations = annotations,
              palette = mapped$palette, has.checkv = !is.null(checkv.features),
              selection.by = selection.by))
}
