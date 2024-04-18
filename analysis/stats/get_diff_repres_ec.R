###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   get_diff_repres_ec.R
###############################################################################
library(stats)
library(progress)
library(dunn.test)


# applies a kruskal-wallis test to find differential expressed column values
# and follows up with Dunn's test for pairwise comparisons
get_diff_repres_ec <- function(data) {
  kruskal_res <- matrix(nrow = ncol(data), ncol = 4)
  colnames(kruskal_res) <- c("kruskal_p", "ind vs. pre", "ind vs. pal",
                             "pre vs. pal")
  rownames(kruskal_res) <- colnames(data)
  
  # Create vector of groups for Kruskal-Wallis test
  groups <- vector(length = nrow(data))
  samples <- rownames(data)
  for (i in seq_len(length(samples))) {
    if (grepl("ind", samples[i], fixed = TRUE)) {
      groups[i] = 1
    } else if (grepl("pre", samples[i], fixed = TRUE)) {
      groups[i] = 2
    } else if (grepl("pal", samples[i], fixed = TRUE)) {
      groups[i] = 3
    } else {
      stop(paste0("invalid group at sample ", i))
    }
  } 
  
  # initialize progress bar
  pb_1 <- progress_bar$new(format = "Time: :elapsedfull [:bar] Iteration :current/:total (:percent)", total = ncol(data))
  pb_2 <- progress_bar$new(format = "Time: :elapsedfull [:bar] Iteration :current/:total (:percent)", total = ncol(data))
  
  # perform kruskal-wallis test for all ec
  for (i in seq_len(ncol(data))) {
    kruskal_test_result <- kruskal.test(data[, i], groups)
    kruskal_res[i, "kruskal_p"] <- kruskal_test_result$p.value
    
    # update progress bar
    pb_1$tick()
  }
  
  # apply bh correction to kruskal p-values
  kruskal_res[, "kruskal_p"] <- p.adjust(kruskal_res[, 1], method = "BH", 
                                         n = length(kruskal_res[, 1]))
  
  # if significant, perform Dunn's test
  for (i in seq_len(ncol(data))) {
    if (kruskal_res[i, "kruskal_p"] < 0.05) {
      capture.output(
        dunn_test_result <- dunn.test(data[, i], groups, method="bh")
      )
      
      kruskal_res[i, "ind vs. pre"] <- dunn_test_result$P.adjusted[1]
      kruskal_res[i, "ind vs. pal"] <- dunn_test_result$P.adjusted[2]
      kruskal_res[i, "pre vs. pal"] <- dunn_test_result$P.adjusted[3]
    } else {
      kruskal_res[i, "ind vs. pre"] <- NA
      kruskal_res[i, "ind vs. pal"] <- NA
      kruskal_res[i, "pre vs. pal"] <- NA
    }
    
    # update progress bar
    pb_2$tick()
  }
  
  return(kruskal_res)
}
