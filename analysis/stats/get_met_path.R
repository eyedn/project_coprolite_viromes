###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   get_met_path.R
###############################################################################


# return df contain information on enzyme class counts of samples
get_met_path <- function(met_pathways, ec_data, ec_met_assoc) {
  sample_met_data <- matrix(0, nrow = length(met_pathways),
                            ncol = ncol(ec_data))
  colnames(sample_met_data) <- colnames(ec_data)
  rownames(sample_met_data) <- met_pathways
  
  all_ec <- rownames(ec_data)
  for (j in seq_len(ncol(ec_data))) {
    for (i in seq_len(nrow(ec_data))) {
      curr_ec <- as.character(all_ec[i])
      curr_pathways <- strsplit(ec_met_assoc[curr_ec, ], ",")
      
      for (k in seq_len(length(curr_pathways))) {
        path <- curr_pathways[[1]][k]
        if (is.na(path)) {
          break
        } else {
          path <- as.character(path)
        }
        
        sample_met_data[path, j] <- sample_met_data[path, j] + ec_data[i, j]
      }
    }
  }
  
  concat_met_data <- get_prop(sample_met_data, c("ind", "pre", "pal"), 
                              met_pathways)
  
  return(concat_met_data)
}
