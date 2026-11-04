###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   prepare_checkv_feature_map.R
###############################################################################


# internal functions ----

prepare.checkv.feature.map <- function(
    features, selected.genome.id, selected.annotation) {
  valid.annotations <- c("viral", "bacterial", "vf")
  if (!(selected.annotation %in% valid.annotations)) {
    stop(
      "selected.annotation must be one of: viral, bacterial, or vf"
    )
  }

  selected <- features %>%
    filter(
      genome.id == selected.genome.id,
      annotation == selected.annotation
    )

  if (selected.annotation %in% c("viral", "bacterial")) {
    selected <- selected %>%
      filter(
        !is.na(ec.number),
        ec.number != "",
        !str_detect(
          str_to_lower(product),
          fixed("hypothetical protein")
        )
      )
  }

  selected <- selected %>%
    mutate(y = if_else(strand == "+", 1, -1))
  return(selected)
}
