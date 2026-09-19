###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   normalize_checkv_lifestyle.R
###############################################################################
# internal functions ----

normalize.checkv.lifestyle <- function(lifestyle) {
  normalized <- str_to_lower(str_trim(lifestyle))
  normalized <- case_when(
    normalized %in% c("virulent", "lytic") ~ "lytic",
    normalized == "temperate" ~ "temperate",
    TRUE ~ normalized
  )
  return(normalized)
}
