###############################################################################
#   Aydin Karatas
#   Project Coprolite Viromes
#   create_all_mds.R
###############################################################################


# append the current time to a given file name
append_time_to_filename <- function(base_name) {
  
  file_name <- paste(baes_name, format(Sys.time(), "%Y%m%d%H%M%S"), sep = "_")
  return(file_name)
}
