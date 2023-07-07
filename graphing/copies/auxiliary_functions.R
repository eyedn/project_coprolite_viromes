###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   auxillary_functions
###############################################################################
library(stats)

# create a vector to color mds by time catagory and orgin
color_by_catagory <- function(df) {
  color_origin <- c()
  color_time <- c()
  samples <- colnames(df)
  for (s in seq_len(length(samples))) {
    origin <- substr(samples[s], 1, 7)
    time <- substr(samples[s], 1, 3)
    color_origin <- c(color_origin, origin)
    color_time <- c(color_time, time)
  }
  return(list(color_time, color_origin))
}

# convert data to normalized CPM; remove outliers
clean_data <- function(df) {
  # convert dataframe to matrix
  df <- as.matrix(df)
  # check which rows and columns have all-zero values
  zero_rows <- which(rowSums(df) == 0)
  zero_cols <- which(colSums(df) == 0)
  # reasign zero_* vectors to 0 if there are no rows or cols to remove
  if (is.na(zero_rows[1])) { zero_rows <- nrow(df)*2 }
  if (is.na(zero_cols[1])) { zero_cols <- ncol(df)*2 } 
  # remove rows and columns with all-zero values
  df <- df[-zero_rows[[1]], -zero_cols[[1]]]
  
  # compute normalization + log transformation
  for (i in seq_len(ncol(df))) {
    df[, i] <- log2((10^6) * df[, i] / sum(df[, i]) + 1)
  }
  
  # remove columns with large values
  # threshold <- mean(df) + 3 * sd(df)  # threshold is within 3 standard dev's
  # df <- df[, apply(df, 2, max) < threshold]
  # return matrix (still named df)
  return(df)
}

# applies a wilcoxon test to a given gene and each samples' counts (1 and 2)
signif_test <- function(subset_1, subset_2, subset_3, max_out) {
  # first, generate non-adjusted p-values
  sig_df <- data.frame(matrix(nrow = nrow(subset_1), ncol = 1))
  colnames(sig_df) <- c("p-val")
  # colnames(sig_df) <- c("p_val", 
  #                       paste0(deparse(substitute(subset_1)), " <m>"),
  #                       paste0(deparse(substitute(subset_1)), "<sd>"),
  #                       paste0(deparse(substitute(subset_2)), " <m>"),
  #                       paste0(deparse(substitute(subset_2)), "<sd>"))
  rownames(sig_df) <- rownames(subset_1)
  for (i in seq_len(nrow(subset_1))) {
    # in wilcox.test, the p-value is stored in index 3
    sig_df[i, 1] <- wilcox.test(as.numeric(subset_1[i, ]),
                                as.numeric(subset_2[i, ]))[[3]]
  }
  # apply BH correction to data and order data based on significance
  sig_df[, 1] <- p.adjust(sig_df[, 1], method = "BH", n = nrow(sig_df))
  # add additional rows for information on subset means and sd
  sig_df$subset_1_mean <- apply(subset_1, 1, mean)
  sig_df$subset_1_sd <- apply(subset_1, 1, sd)
  sig_df$subset_2_mean <- apply(subset_2, 1, mean)
  sig_df$subset_2_sd <- apply(subset_2, 1, sd)
  sig_df$subset_3_mean <- apply(subset_3, 1, mean)
  sig_df$subset_3_sd <- apply(subset_3, 1, sd)
  # order the rows by the p-values (lowest at the top)
  ordered_sig <- sig_df
  ordered_sig <- sig_df[order(sig_df[, 1]), ]
  rownames(ordered_sig) <- rownames(sig_df)[order(sig_df[, 1])]
  # return the top <max_out> observations
  return(ordered_sig[c(1:max_out), , drop = FALSE])
}

# prepare data for heatmap
heat_prep <- function(all_data, sig_data) {
  heat_mat <- as.matrix(all_data[, rownames(sig_data)])
  return(heat_mat)
}
