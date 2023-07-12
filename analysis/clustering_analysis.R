###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   clustering_analysis.R
###############################################################################
setwd("~/Documents/Research/scripts/analysis/clustering/")
# setwd("/u/home/a/ayd1n/project_coprolite_viromes/analysis/clustering")
clustering_functions <- list.files(pattern="*.R")
sapply(clustering_functions, source)
setwd("~/Documents/Research/scripts/analysis/graphing/")
# setwd("/u/home/a/ayd1n/project_coprolite_viromes/analysis/graphing")
graphing_functions <- list.files(pattern="*.R")
sapply(graphing_functions, source)
setwd("~/Documents/Research/scripts/")
# setwd("/u/home/a/ayd1n/project_coprolite_viromes")


# read in raw counts data
# args <- commandArgs(trailingOnly = TRUE)
# raw_counts_csv <- args[1]
# raw_counts <- read.csv(args[1], header = TRUE, row.names = 1)
raw_counts <- read.csv("~/Documents/Research/data/Bacteria_ec_data.csv",
                       header = TRUE, row.names = 1)

# normalize observations within a sample and transform to log( CPM + 1 )
norm_counts <- normalize_data(raw_counts)
scaled_counts <- as.matrix(scale(t(normalize_data(raw_counts))))

# find optimal number of clusters with a wss/silhouette plot
optimal_sil <- get_optimal_clusters(scaled_counts, "silhouette")
optimal_wss <- get_optimal_clusters(scaled_counts, "wss")

# perform bootstrap clustering with kmeans
k <- 4
boot_iter <- 1000
graph_every <- 100
bootstrap_dir <- "../figures/bootstrap"

bootstrap_res <- kmeans_bootstrap(norm_counts, scaled_counts, k, boot_iter, 
                                  graph_every)

bootstrap_cluster_probs <- bootstrap_res[[1]]
bootstrap_mds_info <- bootstrap_res[[2]]
create_all_mds(bootstrap_mds_info, bootstrap_dir)

# perform kmeans clustering of permuations
permute_iter <- 1000
permute_dir <- "../figures/permute"

permute_res <- kmeans_permute(norm_counts, scaled_counts, k, permute_iter, 
                              graph_every)

permute_cluster_probs <- permute_res[[1]]
permute_mds_info <- permute_res[[2]]
create_all_mds(bootstrap_mds_info, permute_dir)

# show clustering behavior
beeswarms_dir <- "../figures/beeswarms"
violin_dir <- "../figures/violin"

create_beeswarm(bootstrap_cluster_probs, "bootstrap", beeswarms_dir, k)
create_beeswarm(permute_cluster_probs, "permutation", beeswarms_dir, k)
create_violin(bootstrap_cluster_probs, permute_cluster_probs,
              c(0.025, 0.975), "confidence", violin_dir, k)
