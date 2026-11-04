###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   bootstrap_checkv_sample_vf.R
###############################################################################


# the report sets the RNG seed before calling this sample-resampling helper.
bootstrap.checkv.sample.vf <- function(data, group.column, group.order,
                                     draws, resample.size = NULL) {
  if (anyDuplicated(data$sample.id) ||
      any(!is.finite(data$vf.orf.prevalence))) {
    stop("Bootstrap input requires one finite observation per sample")
  }
  result <- lapply(group.order, function(group.name) {
    values <- data$vf.orf.prevalence[data[[group.column]] == group.name]
    if (length(values) == 0L) {
      stop("No eligible samples for bootstrap group: ", group.name)
    }
    draw.size <- if (is.null(resample.size)) length(values) else resample.size
    replicate(draws, {
      # index sampling also preserves singleton numeric observations exactly.
      indices <- sample.int(length(values), draw.size, replace = TRUE)
      median(values[indices])
    })
  })
  return(as.data.frame(setNames(result, group.order)))
}
