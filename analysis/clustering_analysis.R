###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   clustering_analysis.R
###############################################################################
setwd("~/Documents/Research/scripts/analysis/clustering/")
clustering_functions <- list.files(pattern="*.R")
sapply(clustering_functions, source)
setwd("~/Documents/Research/scripts/analysis/graphing/")
graphing_functions <- list.files(pattern="*.R")
sapply(graphing_functions, source)
setwd("~/Documents/Research/scripts/analysis/anova/")
anova_functions <- list.files(pattern="*.R")
sapply(anova_functions, source)
setwd("~/Documents/Research/scripts/")


# read in raw counts data
raw_counts <- read.csv("~/Documents/Research/data/Bacteria_ec_data.csv",
                       header = TRUE, row.names = 1)

# normalize observations within a sample and transform to log( CPM + 1 )
norm_counts <- normalize_data(raw_counts)
norm_t_matrix <- scale(t(norm_counts))

# find optimal number of clusters with a wss/silhouette plot
optimal_sil <- get_optimal_clusters(norm_t_matrix, "silhouette")
optimal_wss <- get_optimal_clusters(norm_t_matrix, "wss")
optimal_gap <- get_optimal_clusters(norm_t_matrix, "gap")

# perform bootstrap clustering with kmeans
k <- 4
boot_iter <- 1000
graph_every <- 200
bootstrap_dir <- "../figures/bootstrap"

bootstrap_res <- kmeans_bootstrap(norm_counts, norm_t_matrix, k, boot_iter, 
                                  graph_every)

bootstrap_cluster_probs <- bootstrap_res[[1]]
bootstrap_mds_info <- bootstrap_res[[2]]

# perform kmeans clustering of permuations
permute_iter <- 1000
permute_dir <- "../figures/permute"

permute_res <- kmeans_permute(norm_counts, norm_t_matrix, k, permute_iter, 
                              graph_every)

permute_cluster_probs <- permute_res[[1]]
permute_mds_info <- permute_res[[2]]

# show clustering behavior
beeswarm_dir <- "../figures/beeswarms"
violin_dir <- "../figures/violin"

bootstrap_bee <- create_beeswarm(bootstrap_cluster_probs, "bootstrap", 
                                 beeswarm_dir, k)
permute_bee <- create_beeswarm(permute_cluster_probs, "permutation", 
                               beeswarm_dir, k)
confidence_violin <- create_violin(bootstrap_cluster_probs, 
                                   permute_cluster_probs,
                                   c(0.025, 0.975), 
                                   "confidence", violin_dir, k)

# get differential expression results
diff_repres <- get_diff_repres(norm_t_matrix)

# show differential representation
heat_dir <- "../figures/heat"
diff_repres_heat <- create_heatmap(norm_t_matrix, diff_repres, 50,
                                   "diff_repres", heat_dir)
