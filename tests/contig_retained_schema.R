###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   contig_retained_schema.R
###############################################################################

# exercise retained report code against the existing helper's real schema
suppressPackageStartupMessages(source("analysis/stats/get_diff_repres_cols.R"))
values <- cbind(a = 1:9, b = 9:1)
rownames(values) <- paste0(rep(c("pal", "pre", "ind"), each = 3), 1:9)
result <- get_diff_repres_cols(values)
columns <- names(result)
report <- readLines("analysis/analysis_contigs.Rmd")
start <- which(grepl("^vf.diff.repres\\$kruskal[_.]p <-", report))
end <- which(startsWith(report,
  "vf.diff.repres <- vf.diff.repres[order("))
stopifnot(length(start) == 1, length(end) == 1)
vf.diff.repres <- result
eval(parse(text = report[start:end]))
stopifnot(identical(names(vf.diff.repres), columns),
          nrow(vf.diff.repres) == ncol(values))
cat("PASS: retained gene analysis preserves the helper's p/q column schema\n")
