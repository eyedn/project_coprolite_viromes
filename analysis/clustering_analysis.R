###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   clustering_analysis.R
###############################################################################
setwd("~/Documents/Research/project_coprolite_viromes/analysis/clustering/")
clustering_functions <- list.files(pattern="*.R")
sapply(clustering_functions, source)
setwd("~/Documents/Research/project_coprolite_viromes/analysis/graphing/")
graphing_functions <- list.files(pattern="*.R")
sapply(graphing_functions, source)
setwd("~/Documents/Research/project_coprolite_viromes/analysis/anova/")
anova_functions <- list.files(pattern="*.R")
sapply(anova_functions, source)
setwd("~/Documents/Research/project_coprolite_viromes/")


# read in raw counts data
raw_counts <- read.csv("~/Documents/Research/data/bacterial_gene_counts.csv",
                       header = TRUE, row.names = 1)

# normalize observations within a sample and transform to log( CPM + 1 )
norm_counts <- normalize_data(raw_counts)
norm_t_matrix <- scale(t(norm_counts))

# find optimal number of clusters with a wss/silhouette plot
optimal_sil <- get_optimal_clusters(norm_t_matrix, "silhouette")
optimal_wss <- get_optimal_clusters(norm_t_matrix, "wss")

# perform bootstrap clustering with kmeans
k <- 4
boot_iter <- 1000
graph_every <- 200

bootstrap_res <- kmeans_bootstrap(norm_counts, norm_t_matrix, k, boot_iter, 
                                  graph_every)

bootstrap_cluster_probs <- bootstrap_res[[1]]
bootstrap_mds_info <- bootstrap_res[[2]]

# perform kmeans clustering of permuations
permute_iter <- 1000

permute_res <- kmeans_permute(norm_counts, norm_t_matrix, k, permute_iter, 
                              graph_every)

permute_cluster_probs <- permute_res[[1]]
permute_mds_info <- permute_res[[2]]

# show probabalistic clustering behavior
violin_dir <- "../figures/violin"
permute_name <- paste0("permute_", k)
confidence_name <- paste0("confidence_", k)

permute_violin <- create_violin(permute_cluster_probs, bootstrap_cluster_probs,
                                c(0.025, 0.975), FALSE,
                                permute_name, violin_dir, k)

confidence_violin <- create_violin(bootstrap_cluster_probs, 
                                   permute_cluster_probs, c(0.025, 0.975), 
                                   TRUE, confidence_name, violin_dir, k)

# show differential representation results
subset_top <- 100
color_range <- 10
heat_dir <- "../figures/heat"
heat_name <- paste0("diff_repres_", subset_top)

diff_repres <- get_diff_repres(norm_t_matrix)

diff_repres_heat <- create_heatmap(norm_t_matrix, diff_repres, color_range,
                                   subset_top, heat_name, heat_dir)

# KEGG graphing


# create samples map
create_samples_map("ind")
create_samples_map("pre")
create_samples_map("pal")
