###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   get_met_path.R
###############################################################################


# return df contain information on enzyme class counts of samples
get_met_path <- function(met_pathways, group_labels, ec_data, ec_met_assoc, 
                         diff_repres_ec) {
  sample_met_data <- matrix(0, nrow = length(met_pathways),
                            ncol = ncol(ec_data))
  colnames(sample_met_data) <- colnames(ec_data)
  rownames(sample_met_data) <- met_pathways
  
  ec_data <- ec_data[diff_repres_ec, ]
  
  diff_ec <- rownames(ec_data)
  ec_with_met <- rownames(ec_met_assoc)
  for (j in seq_len(ncol(ec_data))) {
    for (i in seq_len(nrow(ec_data))) {
      curr_ec <- as.character(diff_ec[i])
      
      if (!(curr_ec %in% ec_with_met)) {
        next
      }
      
      curr_pathways <- strsplit(ec_met_assoc[curr_ec, ], ",")
      
      for (k in seq_len(length(curr_pathways[[1]]))) {
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
  
  concat_met_data <- get_cat_CPM(sample_met_data, met_pathways, group_labels,
                                 met_pathways)
  
  return(concat_met_data)
}
