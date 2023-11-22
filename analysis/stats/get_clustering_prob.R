###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   get_clustering_prob.R
###############################################################################


get_clustering_prob <- function(k, cat_1, cat_2) {
  clustered_pairs <- 0
  
  if(missing(cat_2)) {
    # if cat_2 missing, calculate same category clustering probability
    total_pairs <- sum(cat_1) * (sum(cat_1) - 1) * 0.5
    
    for (i in seq_len(k)) {
      clustered_pairs <- clustered_pairs + cat_1[i] * (cat_1[i] - 1) * 0.5
    }
  } else {
    # if cat_2 is not missing, calc. different category clustering probability
    total_pairs <- sum(cat_1) * sum(cat_2)

    for (i in seq_len(k)) {
      clustered_pairs <- clustered_pairs + cat_1[i] * cat_2[i]
    }
  }
  
  return(clustered_pairs / total_pairs)
}
