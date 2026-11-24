###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   checkv_set_a_inputs.R
###############################################################################

# exercise the report's input selection against distinct A and B fixtures.
source("analysis/misc/validate_vf_pool.R")
report <- readLines("analysis/analysis_checkvhits.Rmd")
start <- which(grepl("^checkv.input.paths <-", report))
end <- which(grepl("^checkv.required.columns <-", report)) - 1L
fixture.dir <- tempfile("checkv_versions_")
dir.create(fixture.dir)
for (version in c("VFDB_setA", "VFDB_setB")) {
  suffix <- if (version == "VFDB_setA") "_VFDB_setA" else ""
  for (stem in c("metadata", "features", "vf_hits", "vf_stats", "qc")) {
    write.csv(data.frame(vfdb_version = version,
                         orf_pool = "all_bacterial_prokka_cds"),
              file.path(fixture.dir, paste0("checkv_genome_", stem,
                                             suffix, ".csv")),
              row.names = FALSE)
  }
}
data.dir <- fixture.dir
# include a version declaration immediately before the paths, if present.
if (grepl("^bundle <-", report[start - 1L])) start <- start - 1L
eval(parse(text = report[start:end]))
result <- tryCatch({
  for (path in checkv.input.paths) {
    validate.vf.pool(read.csv(path), bundle$tag)
  }
  TRUE
}, error = identity)
unlink(fixture.dir, recursive = TRUE)
if (inherits(result, "error")) stop(conditionMessage(result))
stopifnot(bundle$tag == "VFDB_setA")
cat("PASS: report selects matching set-A inputs with set-B files present\n")
