###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   rle_normalize.R
###############################################################################
library(DESeq2)


rle_normalize <- function(data) {
  
  # add a pseudo count of 1 to all genes
  psuedo_data <- data + 1
  
  # the first 3 letters of colnames indicates the condition
  col_categories <- data.frame(
    category = factor(substr(colnames(psuedo_data), 1, 3)),
    row_names = colnames(psuedo_data)
  )
  
  # Create DESeqDataSet
  dds <- DESeqDataSetFromMatrix(countData = psuedo_data,
                                colData = col_categories,
                                design = ~ category)
  
  # Normalize data
  dds <- estimateSizeFactors(dds)
  normalized_counts <- counts(dds, normalized = TRUE)
  
  return(normalized_counts)
}
