###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   read_contig_vf_categories.R
###############################################################################


# stream the full inventory, retaining only qualifying VF-bearing ORFs
read.contig.vf.categories <- function(path, stats, vf.reference,
                                       chunk.size = 100000L) {
  types <- readr::cols_only(
    sample = readr::col_character(), contig_id = readr::col_character(),
    feature_id = readr::col_character(), vf_id = readr::col_character(),
    vfdb_version = readr::col_character(), orf_pool = readr::col_character()
  )
  header <- readr::read_csv(path, n_max = 0, col_types = types,
                            progress = FALSE)
  if (!all(names(types$cols) %in% names(header))) {
    stop("ORF inventory is missing identifier or provenance columns")
  }
  chunks <- list()
  callback <- readr::SideEffectChunkCallback$new(function(chunk, position) {
    validate.vf.pool(chunk, "VFDB_setA")
    if (nrow(readr::problems(chunk))) stop("Invalid ORF inventory CSV")
    calls <- chunk %>% filter(!is.na(vf_id), nzchar(trimws(vf_id))) %>%
      transmute(sample.id = sample, contig.id = contig_id, feature_id,
                vf.id = trimws(vf_id))
    if (nrow(calls)) chunks[[length(chunks) + 1L]] <<- calls
  })
  readr::read_csv_chunked(path, callback, chunk_size = chunk.size,
                          col_types = types, progress = FALSE)
  vf <- bind_rows(tibble(sample.id = character(), contig.id = character(),
                          feature_id = character(), vf.id = character()),
                   bind_rows(chunks)) %>% distinct()
  keys <- c("sample.id", "contig.id")
  if (anyNA(vf) || anyDuplicated(vf[c(keys, "feature_id")])) {
    stop("Conflicting qualifying VF calls for one ORF")
  }
  units <- stats %>% transmute(
    sample.id = sample, contig.id = contig_id, category, origin,
    lifestyle = normalize.checkv.lifestyle(lifestyle),
    qualifying.vf.orfs = qualifying_vf_orfs
  )
  if (anyNA(units[c(keys, "category", "origin", "qualifying.vf.orfs")]) ||
      anyDuplicated(units[keys])) stop("Invalid contig metadata keys")
  counts <- vf %>% count(sample.id, contig.id, name = "observed")
  reconciled <- units %>% left_join(counts, by = keys)
  if (nrow(anti_join(vf, units, by = keys)) ||
      any(replace_na(reconciled$observed, 0L) != units$qualifying.vf.orfs)) {
    stop("Inventory and contig qualifying VF ORF counts disagree")
  }
  mapped <- prepare.checkv.vf.categories(
    vf %>% mutate(checkv.filter = "conservative",
                   genome.id = paste(sample.id, contig.id, sep = "/"),
                   annotation = "vf"), vf.reference
  )
  features <- mapped$features %>% select(all_of(keys), feature_id,
                                         vf.id, vf.category) %>%
    left_join(units %>% select(all_of(keys), category, origin), by = keys)
  excluded <- units %>% filter(!lifestyle %in% c("lytic", "temperate")) %>%
    group_by(category, origin, lifestyle) %>%
    summarise(contigs = n(), qualifying.vf.orfs = sum(qualifying.vf.orfs),
              .groups = "drop")
  list(units = units, features = features, palette = mapped$palette,
       excluded = excluded)
}
