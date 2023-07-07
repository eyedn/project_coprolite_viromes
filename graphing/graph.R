###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   graph_functions.R
###############################################################################
source("graph_functions.R")
source("auxiliary_functions.R")
source("clustering_functions.R")

# set seed for reproducibility
seed = 128
set.seed(seed)

# raw counts are stored in a matrix of ec numbers x sample names
bac_raw_counts <- read.csv("~/Documents/Research/data/Bacteria_ec_data.csv",
                           header = TRUE, row.names = 1)

# first, normalize observations within a sample and transform to CPM
# remove samples with very large observations as outliers
# store the matrix as [1] and its scaled transpose as [2]
bac_cpm <- list(clean_data(bac_raw_counts),
                as.matrix(scale(t(clean_data(bac_raw_counts)))))
bac_colors <- color_by_catagory(bac_cpm[[1]])

# find optimal number of clusters with a wss/silhouette plot
bac_wss <- num_clusters(bac_cpm[[2]], "wss")
bac_wss

##### CONCENSUS METHOD FOR KMEANS CLUSERING #####
# perform concensus clustering with kmeans
bac_consensus_info <- consensus_clustering(bac_cpm, 7, 100, 0.8, 
                                           seed, bac_colors, 25, 
                                           "../../figures/clustering_meta")

# show clustering behavior
bac_beeswarm <- bee_plot(bac_consensus_info[[3]], 
                         "../../figures/other_figs_meta", 7)
bac_beeswarm
apply(bac_consensus_info[[3]], 2, summary)

# Extract the error bar values for each boxplot
errorbar_data <- ggplot_build(bac_beeswarm)$data
min_values <- lapply(errorbar_data, function(d) d$ymin)
max_values <- lapply(errorbar_data, function(d) d$ymax)
min_values[[2]]
max_values[[2]]

# assess compactness of a priori groups
bac_ind <- bac_cpm[[1]][, grep("ind", colnames(bac_cpm[[1]]))]
bac_pre <- bac_cpm[[1]][, grep("pre", colnames(bac_cpm[[1]]))]
bac_pal <- bac_cpm[[1]][, grep("pal", colnames(bac_cpm[[1]]))]
bac_wcss <- list("ind" = calculate_WCSS(t(bac_ind)),
                 "pre" = calculate_WCSS(t(bac_pre)), 
                 "pal" = calculate_WCSS(t(bac_pal)))
bac_wcss

# generate colored mapped of samples
samples_map <- colored_samples_map()
samples_map

# # Examine the distribution of ARI values
# summary(bac_consensus_info[[2]])
# hist(bac_consensus_info[[2]], main = "Adjusted Rand Index Distribution")

# ##### find differentially expressed genes #####
# # subset data for each sample category
# bac_subset_ind <- bac_cpm[[2]][grep("ind", rownames(bac_cpm[[2]])), ]
# bac_subset_pre <- bac_cpm[[2]][grep("pre", rownames(bac_cpm[[2]])), ]
# bac_subset_pal <- bac_cpm[[2]][grep("pal", rownames(bac_cpm[[2]])), ]
# # find differentially expressed genes between each pair of subsets
# bac_dif_ind_pre <- signif_test(t(bac_subset_ind), t(bac_subset_pre), 
#                                t(bac_subset_pal), 10)
# bac_dif_ind_pal <- signif_test(t(bac_subset_ind), t(bac_subset_pal), 
#                                t(bac_subset_pre), 10)
# bac_dif_pal_pre <- signif_test(t(bac_subset_pal), t(bac_subset_pre), 
#                                t(bac_subset_ind), 10)
# # display differentially expressed genes on heatmaps
# bac_matrix_ind_pre <- heat_prep(bac_cpm[[2]], bac_dif_ind_pre)
# bac_heatmap_ind_pre <- heat_plot(bac_matrix_ind_pre)
# bac_matrix_ind_pal <- heat_prep(bac_cpm[[2]], bac_dif_ind_pal)
# bac_heatmap_ind_pal <- heat_plot(bac_matrix_ind_pal)
# bac_matrix_pal_pre <- heat_prep(bac_cpm[[2]], bac_dif_pal_pre)
# bac_heatmap_pal_pre <- heat_plot(bac_matrix_pal_pre)
