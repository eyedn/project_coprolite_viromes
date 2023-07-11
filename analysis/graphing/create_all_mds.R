###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   create_all_mds.R
###############################################################################


# create mds plot that displays all points distinguished by cluster
create_all_mds <- function(mds_info, plot_dir) {
  for (i in seq_len(length(mds_info))) {
    # extract mds_info
    all_info <- mds_info[[i]]
    meta_data <- all_info[[1]]
    mds <- all_info[[2]]
    k <- all_info[[3]]
    iter <- all_info[[4]]
   
    mds$cluster <- meta_data[, 1]
    mds$time <- meta_data[, 2]
    mds$origin <- meta_data[, 3]
    colnames(mds) <- c("MDS1", "MDS2", "cluster", "time", "origin")   
    
    # create mds plots
    create_origin_mds(meta_data, mds, iter, plot_dir)
    create_comb_clusters_mds(meta_data, mds, k, iter, plot_dir)
    create_facet_clusters_mds(meta_data, mds, k, iter, plot_dir)
  }
}
