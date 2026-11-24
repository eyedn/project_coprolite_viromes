###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   prepare_checkv_vf_categories.R
###############################################################################


prepare.checkv.vf.categories <- function(features, vf.reference) {
  if (!all(c("VFID", "VFcategory") %in% names(vf.reference))) {
    stop("VF reference requires VFID and VFcategory")
  }
  reference <- vf.reference %>%
    transmute(vf.id = trimws(as.character(VFID)),
              vf.category = trimws(as.character(VFcategory))) %>%
    filter(!is.na(vf.id), nzchar(vf.id),
           !is.na(vf.category), nzchar(vf.category)) %>%
    distinct()
  if (anyDuplicated(reference$vf.id)) {
    stop("VF reference has ambiguous categories for a VF ID")
  }
  vf <- features %>% filter(annotation == "vf")
  keys <- c("checkv.filter", "genome.id", "feature_id")
  if (anyNA(vf[c(keys, "vf.id")]) || anyDuplicated(vf[keys])) {
    stop("VF categories require one qualifying call per ORF")
  }
  vf <- vf %>% left_join(reference, by = "vf.id") %>%
    mutate(vf.category = replace_na(vf.category, "Unmapped VF category"))
  if (nrow(vf) != sum(features$annotation == "vf")) {
    stop("VF category join changed qualifying ORF counts")
  }
  categories <- sort(setdiff(unique(reference$vf.category),
                             "Unmapped VF category"), method = "radix")
  palette <- setNames(grDevices::hcl.colors(length(categories), "Dark 3"),
                      categories)
  palette <- c(palette, "Unmapped VF category" = "#808080")
  return(list(features = vf, palette = palette))
}
