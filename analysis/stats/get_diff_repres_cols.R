###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   get_diff_repres_cols.R
###############################################################################


library(stats)
library(progress)
library(dunn.test)

# applies a kruskal-wallis test to find differentially represented columns
# and follows up with Dunn's test for pairwise comparisons
get_diff_repres_cols <- function(data) {
  
  # results matrix: raw p for KW + raw p for 3 pairwise Dunn contrasts
  kruskal_res <- matrix(nrow = ncol(data), ncol = 4)
  colnames(kruskal_res) <- c(
    "kruskal_p",
    "ind_vs_pre_p",
    "ind_vs_pal_p",
    "pre_vs_pal_p"
  )
  rownames(kruskal_res) <- colnames(data)
  
  # groups for Kruskal-Wallis and Dunn tests
  groups <- substr(rownames(data), 1, 3)
  
  # progress bars
  pb_1 <- progress_bar$new(
    format = "Kruskal: Time: :elapsedfull [:bar] :current/:total (:percent)",
    total  = ncol(data)
  )
  pb_2 <- progress_bar$new(
    format = "Dunn:    Time: :elapsedfull [:bar] :current/:total (:percent)",
    total  = ncol(data)
  )
  
  ## 1) run Kruskal–Wallis for all columns
  for (i in seq_len(ncol(data))) {
    kruskal_test_result <- kruskal.test(data[, i], groups)
    kruskal_res[i, "kruskal_p"] <- kruskal_test_result$p.value
    pb_1$tick()
  }
  
  ## 1a) Multiple-testing correction across all Kruskal–Wallis tests
  kruskal_q <- p.adjust(kruskal_res[, "kruskal_p"], method = "BH")
  
  ## 2) use Dunn's test for columns with significant Kruskal p-value
  for (i in seq_len(ncol(data))) {
    # keep original behavior: threshold on raw p; you can change to kruskal_q[i] < 0.05 if desired
    if (kruskal_res[i, "kruskal_p"] < 0.05) {
      capture.output(
        dunn_test_result <- dunn.test(data[, i], groups, method = "bh")
      )
      
      # the P.adjusted values from Dunn's test are already BH-corrected within this feature
      kruskal_res[i, "ind_vs_pre_p"] <- dunn_test_result$P.adjusted[1]
      kruskal_res[i, "ind_vs_pal_p"] <- dunn_test_result$P.adjusted[2]
      kruskal_res[i, "pre_vs_pal_p"] <- dunn_test_result$P.adjusted[3]
    } else {
      kruskal_res[i, "ind_vs_pre_p"] <- NA_real_
      kruskal_res[i, "ind_vs_pal_p"] <- NA_real_
      kruskal_res[i, "pre_vs_pal_p"] <- NA_real_
    }
    
    pb_2$tick()
  }
  
  ## 2a) Multiple-testing correction across all features for each pairwise contrast
  res_df <- as.data.frame(kruskal_res)
  
  res_df$kruskal_q      <- kruskal_q
  res_df$ind_vs_pre_q   <- p.adjust(res_df$ind_vs_pre_p, method = "BH")
  res_df$ind_vs_pal_q   <- p.adjust(res_df$ind_vs_pal_p, method = "BH")
  res_df$pre_vs_pal_q   <- p.adjust(res_df$pre_vs_pal_p, method = "BH")
  
  return(res_df)
}
