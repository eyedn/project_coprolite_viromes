#!/bin/bash
###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       2_predict_viral_character.sh
###############################################################################


code_dir="${VIROME_CODE_DIR:-$HOME/project_coprolite_viromes}"
source "$code_dir/general_bash_functions/slurm.sh"
validate_cpus "${3:-}" || exit 2


cd "${VIROME_CODE_DIR:-$HOME/project_coprolite_viromes}" || exit 1


origin=$1
origin_parent=$2
num_cores=$3 

# predict phage contigs and their lifestyle, family, and hosts
. phabox_predictions/phage_predictions.sh "$origin" "$origin_parent" "$num_cores"

# annotate phages for viral genes
. prokka_annotations/bacterial_annot_phage.sh "$origin" "$origin_parent" "$num_cores"

# annotate phages for bacterial genes
. prokka_annotations/viral_annot_phage.sh "$origin" "$origin_parent" "$num_cores"
