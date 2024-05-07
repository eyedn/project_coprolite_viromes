###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   get_diversity_indeces.R
###############################################################################
library(vegan)
library(dunn.test)


# generate a diversity index
get_diversity_indeces <- function(data, div_index, num_iter) {
  # subset data based on sample category
  ind_samples <- data[grep("^ind", rownames(data)), ]
  pre_samples <- data[grep("^pre", rownames(data)), ]
  pal_samples <- data[grep("^pal", rownames(data)), ]
  
  # calculate diversity index
  ind_diversity <- diversity(ind_samples, index = div_index)
  pre_diversity <- diversity(pre_samples, index = div_index)
  pal_diversity <- diversity(pal_samples, index = div_index)
  diversity_data <- data.frame(
    diversity_index = c(ind_diversity, pre_diversity, pal_diversity),
    Group = factor(rep(c("ind", "pre", "pal"), 
                       times = c(length(ind_diversity), 
                                 length(pre_diversity), 
                                 length(pal_diversity))))
    )

  # bootstrap median diversity index
  pb <- progress_bar$new(format = "Time: :elapsedfull [:bar] Iteration :current/:total (:percent)", total = num_iter)
  
  boot_stats <- matrix(nrow = num_iter, ncol = 3)
  colnames(boot_stats) <- c("ind", "pre", "pal")
  
  # subset data by category for re-sampling later
  ind_subset <- diversity_data[diversity_data$Group == "ind", ]
  pal_subset <- diversity_data[diversity_data$Group == "pal", ]
  pre_subset <- diversity_data[diversity_data$Group == "pre", ]
  
  # medians for each bootstrap iteration
  for (i in seq_len(num_iter)) {
    # create re-sampled data
    ind_resample <- ind_subset[sample(nrow(ind_subset), nrow(ind_subset),
                                      replace = TRUE), ]
    pal_resample <- pal_subset[sample(nrow(pal_subset), nrow(pal_subset),
                                      replace = TRUE), ]
    pre_resample <- pre_subset[sample(nrow(pre_subset), nrow(pre_subset),
                                      replace = TRUE), ]
    
    boot_stats[i, "ind"] <- median(ind_resample$diversity_index)
    boot_stats[i, "pre"] <- median(pre_resample$diversity_index)
    boot_stats[i, "pal"] <- median(pal_resample$diversity_index)
    
    # update progress bar
    pb$tick()   
  }
  
  # perform kruskal wallis testing with BH correction
  kruskal <- kruskal.test(diversity_index ~ Group, data = diversity_data)
  kruskal$p.value <- p.adjust(kruskal$p.value, method = "BH")
  print(kruskal)

  # dunn's test with BH correction
  dunn_test <- dunn.test(diversity_data$diversity_index,
                         diversity_data$Group,
                         method = "bh")
  print(dunn_test)
  
  return(list(diversity_data, boot_stats))
}

