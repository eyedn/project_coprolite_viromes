###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   analysis.R
###############################################################################
setwd("~/Documents/Research/project_coprolite_viromes/analysis/general_R_functions/")
general_functions <- list.files(pattern="*.R")
sapply(general_functions, source)
setwd("~/Documents/Research/project_coprolite_viromes/analysis/clustering/")
cluster_functions <- list.files(pattern="*.R")
sapply(cluster_functions, source)
setwd("~/Documents/Research/project_coprolite_viromes/analysis/diff_repres/")
diff_functions <- list.files(pattern="*.R")
sapply(diff_functions, source)
setwd("~/Documents/Research/project_coprolite_viromes/")


# define script constants
set.seed(seed = 621)
k <- 4
iterations <- 10000
subset_top <- 100
color_range <- 10
violin_dir <- "../figures/violin"
heat_dir <- "../figures/heat"
jitter_dir <- "../figures/jitter"
confidence_name <- paste0("confidence_", k)
heat_name <- paste0("diff_repres_", subset_top)
jitter_name <- paste0("ec_repres_", subset_top)
star_bounds <- list(list(0.1, 0.9), list(0.025, 0.975), list(0.01, 0.99),
                    list(0.001, 0.999))

# read in raw counts data
raw_counts <- read.csv("~/Documents/Research/data/bacterial_gene_counts.csv",
                       header = TRUE, row.names = 1)

# normalize observations within a sample and transform to log( CPM + 1 )
norm_counts <- normalize_data(raw_counts)
norm_t_matrix <- scale(t(norm_counts))

# find optimal number of clusters with a wss/silhouette plot
optimal_sil <- get_optimal_clusters(norm_t_matrix, "silhouette")
optimal_wss <- get_optimal_clusters(norm_t_matrix, "wss")

# perform kmeans with boostraping and permutations
bootstrap_res <- kmeans_bootstrap(norm_t_matrix, k, iterations)
permute_res <- kmeans_permute(norm_t_matrix, k, iterations)

# show clustering results by combining bootstrap and permutation res
cluster_results <- get_clustering_res(bootstrap_res, permute_res, star_bounds,
                                      iterations)
confidence_violin <- create_violin(bootstrap_res, cluster_results,
                                   confidence_name, violin_dir)

# show differential representation results
diff_repres <- get_diff_repres_ec(norm_t_matrix)
create_heatmap(norm_t_matrix, diff_repres, color_range, subset_top,
               heat_name, heat_dir)

# show ec proportions
median_ec <- get_cat_medians(norm_t_matrix[, rownames(diff_repres)[1:100]])
ec_jitter <- create_jitter(median_ec, jitter_name, jitter_dir)
get_diff_repres_class(median_ec)


pal_ec <- read.csv("~/Documents/Research/data/pal_ec.csv", header = F)
all_ec <- read.csv("~/Documents/Research/data/diff_repress_bacterial_ec.csv",
                   header = TRUE, row.names = 1)

pal_diff_repres <- all_ec[pal_ec[, 1], , drop = FALSE]
pal_diff_repres <- pal_diff_repres[, 1:3]





