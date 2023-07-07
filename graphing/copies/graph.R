###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   graph_functions.R
###############################################################################
source("graph_functions.R")
source("auxiliary_functions.R")
source("clustering_functions.R")

# the only arg required in the path to the directory all data is stored in
bac_raw_counts <- read.csv("~/Documents/Research/data/data_Bacteria_raw_counts.csv",
                           header = TRUE, row.names = 1)
# vir_raw_counts <- read.csv('../data/data_Viruses_raw_counts.csv',
#                            header = T, row.names = 1)

# first, normalize observations within a sample and transform to CPM
# remove samples with very large observations as outliers
# store the matrix as [1] and its scaled transpose as [2]
bac_cpm <- list(clean_data(bac_raw_counts),
                as.matrix(scale(t(clean_data(bac_raw_counts)))))
bac_colors <- color_by_catagory(bac_cpm[[1]])
# perform pca dimension reduction on bacterial annotations
bac_pca <- prcomp(bac_cpm[[2]])
# mds
bac_mds <- cmdscale(dist(bac_cpm[[2]]))
plot(bac_mds[, 1], bac_mds[, 2])
bac_mds <- cmdscale(dist(t(bac_cpm[[1]])))
plot(bac_mds[, 1], bac_mds[, 2])

# find optimal number of clusters with a wss/silhouette plot
bac_wss <- fviz_nbclust(bac_cpm[[2]], kmeans, method = "wss") +
  labs(subtitle = "Elbow method")
bac_wss
bac_sil <- fviz_nbclust(bac_cpm[[2]], kmeans, method = "silhouette") +
  labs(subtitle = "Elbow method")
bac_sil

##### CONCENSUS METHOD FOR KMEANS CLUSERING #####
# perform concensus clustering with kmeans
bac_consensus_info <- consensus_clustering(bac_cpm, 4, 1, 0.8, 0, 
                                         bac_colors, 25, "Bacterial", 
                                         "../../figures/concensus/")
# graph consensus matrix with heatmap
heatmap(bac_consensus_info[[1]], xlab = "Data Point", ylab = "Data Point",
        main = "Consensus Matrix")

# Examine the distribution of ARI values
summary(bac_consensus_info[[2]])
hist(bac_consensus_info[[2]], main = "Adjusted Rand Index Distribution")

# show clustering behavior
bac_concensus_pairs <- clus_plot(bac_consensus_info[[4]], "../../figures/concensus/")
bac_concensus_pairs

##### MDS #####
mds_result <- cmdscale(dist(cleaned_data))

##### find differentially expressed genes #####
# subset data for each sample category
bac_subset_ind <- bac_cpm[[2]][grep("ind", rownames(bac_cpm[[2]])), ]
bac_subset_pre <- bac_cpm[[2]][grep("pre", rownames(bac_cpm[[2]])), ]
bac_subset_pal <- bac_cpm[[2]][grep("pal", rownames(bac_cpm[[2]])), ]
# find differentially expressed genes between each pair of subsets
bac_dif_ind_pre <- signif_test(t(bac_subset_ind), t(bac_subset_pre), 
                               t(bac_subset_pal), 10)
bac_dif_ind_pal <- signif_test(t(bac_subset_ind), t(bac_subset_pal), 
                               t(bac_subset_pre), 10)
bac_dif_pal_pre <- signif_test(t(bac_subset_pal), t(bac_subset_pre), 
                               t(bac_subset_ind), 10)
# display differentially expressed genes on heatmaps
bac_matrix_ind_pre <- heat_prep(bac_cpm[[2]], bac_dif_ind_pre)
bac_heatmap_ind_pre <- heat_plot(bac_matrix_ind_pre)
bac_matrix_ind_pal <- heat_prep(bac_cpm[[2]], bac_dif_ind_pal)
bac_heatmap_ind_pal <- heat_plot(bac_matrix_ind_pal)
bac_matrix_pal_pre <- heat_prep(bac_cpm[[2]], bac_dif_pal_pre)
bac_heatmap_pal_pre <- heat_plot(bac_matrix_pal_pre)
