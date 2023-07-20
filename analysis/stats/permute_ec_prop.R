###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   permute_ec_prop.R
###############################################################################


# permute raw counts to define CI for ec prop. counts
permute_ec_prop <- function(raw_data, num_iter) {
  permute_res <- list()
  
  for (i in seq_len(num_iter)) {
    permute_idx <- sample(ncol(raw_data), ncol(raw_data), replace = FALSE)
    raw_permute <- raw_data[, permute_idx]
    colnames(raw_permute) <- colnames(raw_data)

    permute_res[[i]] <- get_ec_prop(raw_permute)
    print(paste0(Sys.time(), " | iterations complete:", i))
  }
  
  return(permute_res)
}
