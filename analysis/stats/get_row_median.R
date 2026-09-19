###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   get_row_median.R
###############################################################################
# gets median value
# get_row_median <- function(data, num_iter, row_num, cats, max_resample = NULL) {
#   # progress bar
#   pb <- progress_bar$new(
#     format = "Time: :elapsedfull [:bar] Iteration :current/:total (:percent)",
#     total = num_iter
#   )
#   
#   # pull the target row as numeric; drop NA/Inf columns
#   y <- suppressWarnings(as.numeric(data[row_num, ]))
#   names(y) <- colnames(data)
#   keep <- is.finite(y) & !is.na(y)
#   y <- y[keep]
#   
#   # pre-compute vectors per category (substring match in column names)
#   vec_list <- setNames(vector("list", length(cats)), cats)
#   for (cat in cats) {
#     vec_list[[cat]] <- y[grepl(cat, names(y), fixed = TRUE)]
#   }
#   
#   # container for bootstrap stats
#   boot_stats <- matrix(NA_real_, nrow = num_iter, ncol = length(cats))
#   colnames(boot_stats) <- cats
#   
#   # bootstrap
#   for (i in seq_len(num_iter)) {
#     for (j in seq_along(cats)) {
#       v <- vec_list[[j]]
#       if (is.null(max_resample)) {
#         resample_size <- length(v)
#       } else {
#         resample_size <- max_resample
#       }
#       boot_stats[i, j] <- if (length(v)) median(sample(v, resample_size, replace = TRUE), na.rm = TRUE) else NA_real_
#     }
#     pb$tick()
#   }
#   
#   boot_stats
# }

get_row_median <- function(
    data,
    num_iter,
    row_num,
    cats,
    max_resample = NULL,
    bootstrap = TRUE
) {
  
  # pull the target row as numeric; drop NA/Inf columns
  y <- suppressWarnings(as.numeric(data[row_num, ]))
  names(y) <- colnames(data)
  keep <- is.finite(y) & !is.na(y)
  y <- y[keep]
  
  # pre-compute vectors per category (substring match in column names)
  vec_list <- setNames(vector("list", length(cats)), cats)
  for (cat in cats) {
    vec_list[[cat]] <- y[grepl(cat, names(y), fixed = TRUE)]
  }
  
  # no bootstrap: return 1-row data frame (same shape as bootstrap output)
  # ------------------------------------------------------------
  if (!bootstrap) {
    med_vec <- vapply(
      vec_list,
      function(v) if (length(v)) median(v, na.rm = TRUE) else NA_real_,
      numeric(1)
    )
    out <- as.data.frame(as.list(med_vec), check.names = FALSE)
    return(out)
  }
  

  # bootstrap
  pb <- progress_bar$new(
    format = "Time: :elapsedfull [:bar] Iteration :current/:total (:percent)",
    total = num_iter
  )
  
  boot_stats <- matrix(NA_real_, nrow = num_iter, ncol = length(cats))
  colnames(boot_stats) <- cats
  
  for (i in seq_len(num_iter)) {
    for (j in seq_along(cats)) {
      v <- vec_list[[j]]
      resample_size <- if (is.null(max_resample)) length(v) else max_resample
      boot_stats[i, j] <-
        if (length(v))
          median(sample(v, resample_size, replace = TRUE), na.rm = TRUE)
      else
        NA_real_
    }
    pb$tick()
  }
  
  boot_stats
}

