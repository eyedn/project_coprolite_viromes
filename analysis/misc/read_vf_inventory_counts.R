# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# ___
# read_vf_inventory_counts.R
# ______________________________________________________________________________
# Stream only provenance and count fields; keep accumulated counts, not ORFs.
read.vf.inventory.counts <- function(path, version, samples,
                                      chunk.size = 100000L) {
  column.types <- readr::cols_only(
    sample = readr::col_character(), vf_id = readr::col_character(),
    vfdb_version = readr::col_character(), orf_pool = readr::col_character()
  )
  header <- readr::read_csv(path, n_max = 0, col_types = column.types,
                            progress = FALSE)
  if (!all(c("sample", "vf_id", "vfdb_version", "orf_pool") %in%
           names(header))) {
    stop("ORF inventory is missing count or provenance columns")
  }
  counts <- tibble::tibble(vf_id = character(), sample = character(),
                           n = integer())
  callback <- readr::SideEffectChunkCallback$new(function(chunk, position) {
    validate.vf.pool(chunk, version)
    counts <<- combine.vf.inventory.counts(counts, chunk, samples)
  })
  readr::read_csv_chunked(
    path, callback = callback, chunk_size = chunk.size,
    col_types = column.types, progress = FALSE
  )
  return(counts)
}
