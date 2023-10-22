###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   analysis.R
###############################################################################
setwd("~/Documents/Research/project_coprolite_viromes/analysis/general_R_functions/")
general_functions <- list.files(pattern="*.R")
sapply(general_functions, source)
rm(general_functions)
setwd("~/Documents/Research/project_coprolite_viromes/analysis/clustering/")
cluster_functions <- list.files(pattern="*.R")
sapply(cluster_functions, source)
rm(cluster_functions)
setwd("~/Documents/Research/project_coprolite_viromes/analysis/diff_repres/")
diff_functions <- list.files(pattern="*.R")
sapply(diff_functions, source)
rm(diff_functions)
setwd("~/Documents/Research/project_coprolite_viromes/analysis/predictions/")
pred_functions <- list.files(pattern="*.R")
sapply(pred_functions, source)
rm(pred_functions)
setwd("~/Documents/Research/project_coprolite_viromes/")


####### 1. constants ##########################################################
set.seed(seed = 123)

k <- 4
iterations <- 1000
subset_top <- 100
color_range <- 10
star_bounds <- list(list(0.1, 0.9), list(0.025, 0.975), list(0.01, 0.99),
                    list(0.001, 0.999))

violin_dir <- "../project_coprolite_viromes_NOT_CODE/figures/violin"
heat_dir <- "../project_coprolite_viromes_NOT_CODE/figures/heat"
jitter_dir <- "../project_coprolite_viromes_NOT_CODE/figures/jitter"

voilin_vir_ec <- paste0("clustering_vir_ec_", k)
voilin_lifestyle <- "lifestyle"
voilin_phage_ec <- paste0("clustering_phage_ec_", k)
voilin_phage_fam <- paste0("clustering_phage_fam_", k)
voilin_phage_host <- paste0("clustering_phage_host_", k)

heat_vir_ec <- paste0("diff_repres_vir_ec_", subset_top)
heat_vir_ec_no_key <- paste0("diff_repres_vir_ec_no_key", subset_top)
heat_phage_ec <- paste0("diff_repres_phage_ec_", subset_top)
heat_phage_fam <- paste0("diff_repres_phage_fam_", subset_top)
heat_phage_host <- paste0("diff_repres_phage_host_", subset_top)

jitter_vir_classes <- paste0("vir_classes_", subset_top)
jitter_phage_classes <- paste0("phage_classes_", subset_top)

####### 2. vir_ec ############################################################
# read in raw counts data
vir_ec_counts <- read.csv("~/Documents/Research/project_coprolite_viromes_NOT_CODE/data/vir_phage_ec_counts.csv",
                          header = TRUE, row.names = 1)

# normalize observations within a sample and transform to log( CPM + 1 )
vir_ec_norm <- normalize_data(vir_ec_counts)
vir_ec_t_mat <- scale(t(vir_ec_norm))

# find optimal number of clusters with a wss/silhouette plot
vir_ec_optimal_sil <- get_optimal_clusters(vir_ec_t_mat, "silhouette")
vir_ec_optimal_wss <- get_optimal_clusters(vir_ec_t_mat, "wss")

# perform kmeans with boostraping and permutations
vir_ec_boot_res <- kmeans_bootstrap(vir_ec_t_mat, k, iterations)
vir_ec_perm_res <- kmeans_permute(vir_ec_t_mat, k, iterations)

# show clustering results by combining bootstrap and permutation res
vir_ec_clus_res <- get_clustering_res(vir_ec_boot_res, vir_ec_perm_res,
                                      star_bounds, iterations)
vir_ec_clus_violin <- create_violin(vir_ec_boot_res, vir_ec_clus_res,
                                    voilin_vir_ec, violin_dir)

# show differential representation results
vir_ec_diff_repres <- get_diff_repres_ec(vir_ec_t_mat)
vir_ec_heatmap <- create_heatmap(vir_ec_t_mat, vir_ec_diff_repres, color_range,
                                 subset_top, heat_vir_ec, heat_dir)

# show ec proportions
vir_ec_median <- get_cat_medians(vir_ec_t_mat[, rownames(vir_ec_diff_repres)[1:subset_top]])
get_diff_repres_class(vir_ec_median)
vir_ec_jitter <- create_jitter(vir_ec_median, c(1:7), jitter_vir_classes,
                               jitter_dir)

####### 3. phage_type #########################################################
# test lifestyle counts
lifestyle_counts <- read.csv("../project_coprolite_viromes_NOT_CODE/data/lifestyle_counts.csv",
                             header = TRUE, row.names = 1)
lifestyle_boot_res <- get_median_lifestyles(lifestyle_counts, iterations)

lifestyle_voilin <- create_lifestyle_voilin(lifestyle_boot_res,
                                            voilin_lifestyle, violin_dir)
lifestyle <- melt(lifestyle_boot_res)
kruskal.test(lifestyle$value, lifestyle$Var2)

####### 4. phage_ec ###########################################################
# read in raw counts data
phage_ec_counts <- read.csv("~/Documents/Research/project_coprolite_viromes_NOT_CODE/data/phage_ec_counts.csv",
                            header = TRUE, row.names = 1)

# normalize observations within a sample and transform to log( CPM + 1 )
phage_ec_norm <- normalize_data(phage_ec_counts)
phage_ec_t_mat <- scale(t(phage_ec_norm))

# find optimal number of clusters with a wss/silhouette plot
phage_ec_optimal_sil <- get_optimal_clusters(phage_ec_t_mat, "silhouette")
phage_ec_optimal_wss <- get_optimal_clusters(phage_ec_t_mat, "wss")

# perform kmeans with boostraping and permutations
phage_ec_boot_res <- kmeans_bootstrap(phage_ec_t_mat, k, iterations)
phage_ec_perm_res <- kmeans_permute(phage_ec_t_mat, k, iterations)

# show clustering results by combining bootstrap and permutation res
phage_ec_clus_res <- get_clustering_res(phage_ec_boot_res, phage_ec_perm_res,
                                        star_bounds, iterations)
phage_ec_clus_violin <- create_violin(phage_ec_boot_res, phage_ec_clus_res,
                                      voilin_phage_ec, violin_dir)

# show differential representation results
phage_ec_diff_repres <- get_diff_repres_ec(phage_ec_t_mat)
create_heatmap(phage_ec_t_mat, phage_ec_diff_repres, color_range, subset_top,
               heat_phage_ec, heat_dir)

# show ec proportions
phage_ec_median <- get_cat_medians(phage_ec_t_mat[, rownames(phage_ec_diff_repres)[1:subset_top]])
get_diff_repres_class(phage_ec_median)
phage_ec_jitter <- create_jitter(phage_ec_median, c(1:6), jitter_phage_classes,
                                 jitter_dir)

# ####### 5. phage_fam ##########################################################
# # read in raw counts data
# phage_fam_counts <- read.csv("~/Documents/Research/data/families_counts.csv",
#                              header = TRUE, row.names = 1)
# phage_fam_counts <- phage_fam_counts[c(2:nrow(phage_fam_counts)), ]
# 
# # normalize observations within a sample and transform to log( CPM + 1 )
# phage_fam_norm <- normalize_data(phage_fam_counts)
# phage_fam_t_mat <- scale(t(phage_fam_norm))
# 
# # find optimal number of clusters with a wss/silhouette plot
# phage_fam_optimal_sil <- get_optimal_clusters(phage_fam_t_mat, "silhouette")
# phage_fam_optimal_wss <- get_optimal_clusters(phage_fam_t_mat, "wss")
# 
# # perform kmeans with boostraping and permutations
# phage_fam_boot_res <- kmeans_bootstrap(phage_fam_t_mat, k, iterations)
# phage_fam_perm_res <- kmeans_permute(phage_fam_t_mat, k, iterations)
# 
# # show clustering results by combining bootstrap and permutation res
# phage_fam_clus_res <- get_clustering_res(phage_fam_boot_res, phage_fam_perm_res,
#                                          star_bounds, iterations)
# phage_fam_clus_violin <- create_violin(phage_fam_boot_res, phage_fam_clus_res,
#                                        voilin_phage_fam, violin_dir)
# 
# # show differential representation results
# phage_fam_diff_repres <- get_diff_repres_ec(phage_fam_t_mat)
# create_heatmap(phage_fam_t_mat, phage_fam_diff_repres, color_range, subset_top,
#                heat_phage_fam, heat_dir)
# 
# ####### 6. phage_host #########################################################
# # read in raw counts data
# phage_host_counts <- read.csv("~/Documents/Research/data/host_counts.csv",
#                               header = TRUE, row.names = 1)
# phage_host_counts <- phage_host_counts[c(2:nrow(phage_host_counts)), ]
# 
# # normalize observations within a sample and transform to log( CPM + 1 )
# phage_host_norm <- normalize_data(phage_host_counts)
# phage_host_t_mat <- scale(t(phage_host_norm))
# 
# # find optimal number of clusters with a wss/silhouette plot
# phage_host_optimal_sil <- get_optimal_clusters(phage_host_t_mat, "silhouette")
# phage_host_optimal_wss <- get_optimal_clusters(phage_host_t_mat, "wss")
# 
# # perform kmeans with boostraping and permutations
# phage_host_boot_res <- kmeans_bootstrap(phage_host_t_mat, k, iterations)
# phage_host_perm_res <- kmeans_permute(phage_host_t_mat, k, iterations)
# 
# # show clustering results by combining bootstrap and permutation res
# phage_host_clus_res <- get_clustering_res(phage_host_boot_res, phage_host_perm_res,
#                                           star_bounds, iterations)
# phage_host_clus_violin <- create_violin(phage_host_boot_res, phage_host_clus_res,
#                                         voilin_phage_host, violin_dir)
# 
# # show differential representation results
# phage_host_diff_repres <- get_diff_repres_ec(phage_host_t_mat)
# create_heatmap(phage_host_t_mat, phage_host_diff_repres, color_range, subset_top,
#                heat_phage_host, heat_dir)
# 
