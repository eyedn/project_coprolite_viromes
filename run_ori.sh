#!/bin/bash
###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       run_ori.sh
###############################################################################


set -euo pipefail

export VIROME_CODE_DIR="${VIROME_CODE_DIR:-$HOME/project_coprolite_viromes}"
cd "$VIROME_CODE_DIR"
for FILE in general_bash_functions/* ; do source $FILE ; done


# paleo samples labeled as pal-{location} :
#       pal-AUT pal-AWC pal-BEL pal-BMS pal-ENG pal-ZAF pal-ZAP
# industrial samples labeled as ind-{location} :
#       ind-CHN ind-DNK ind-ESP ind-USA
# pre-industrial samples labeled as pre-{location} :
#       pre-FJI pre-MDG pre-MEX pre-PER pre-TZA
valid_ori=( pal-AUT pal-AWC pal-BEL pal-BMS pal-ENG pal-ZAF pal-ZAP \
            ind-CHN ind-DNK ind-ESP ind-USA \
            pre-FJI pre-MDG pre-MEX pre-NPL pre-PER pre-TZA \
            pre-source ind-source soil \
            checkv-conservative checkv-aggressive \
            test all )
            
# read in arguments by flag and assign them to variables
while getopts "s:o:p:d:c:" opt; do
  case $opt in
    s) script_name="$OPTARG";;
    o) origin="$OPTARG";;
    p) project_dir="$OPTARG";;
    d) data_per_core="$OPTARG";;
    c) cores="$OPTARG";;
    *) echo "Unknown option: -$opt" >&2; exit 1;;
  esac
done

# check that all arguements were provided
args=("script_name" "origin" "project_dir" "data_per_core" "cores")
for arg in "${args[@]}"; do
  # if an argument is empty, it may have not been provided to the script
  if [ -z "${!arg:-}" ]; then
    echo "ERROR: missing <$arg>."
    echo "Usage Instructions: ./run_ori.sh -s <script_name> -o <origin> -p <project_dir> -d <data_per_core> -c <cores>"
    exit 1
  # check orgin name to be in the list of valid origins
  elif [ "$arg" == "origin" ]; then
    check_args "${valid_ori[*]}" "$origin"
  fi
done

# validate resources and manifests before submission.
if [ "$origin" = "all" ] || [[ "$origin" = checkv-* ]]; then
    total_samples=1
else
    total_samples=$(manifest_count \
        "${project_dir}/samples/${origin}_samples.txt")
fi
if [[ ! -f "$script_name" ]]; then
    echo "missing worker script: $script_name" >&2
    exit 2
fi
job_name="${origin}.$(basename "$script_name" .sh)"
joblogs_output="$SCRATCH/joblogs/$origin/"
submit_slurm "$job_name" "$joblogs_output" "$total_samples" \
    "$cores" "$data_per_core" END,FAIL \
    "$script_name" "$origin" "$project_dir" "$cores"
