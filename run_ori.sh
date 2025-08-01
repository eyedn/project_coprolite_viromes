#!/bin/bash
###############################################################################
#     Aydin Karatas
#     Project Coprolite Viromes
#     run_ori.sh 
###############################################################################
cd $HOME/project_coprolite_viromes
for FILE in general_bash_functions/* ; do source $FILE ; done

# valid origin labels
valid_ori=( pal-AWC pal-BEL pal-BMS pal-ENG pal-ZAF pal-ZAP \
            ind-DNK ind-ESP ind-USA \
            pre-FJI pre-MDG pre-MEX pre-PER pre-TZA \
            test all )

# parse command line arguments
while getopts "s:o:p:d:c:h:" opt; do
  case $opt in
    s) script_name="$OPTARG";;
    o) origin="$OPTARG";;
    p) project_dir="$OPTARG";;
    d) data_per_core="$OPTARG";;
    c) cores="$OPTARG";;
    h) hold_jid="$OPTARG";;
    *) echo "Unknown option: -$opt" >&2; exit 1;;
  esac
done

# check that all required arguments were provided
args=("script_name" "origin" "project_dir" "data_per_core" "cores")
for arg in "${args[@]}"; do
  if [ -z "${!arg}" ]; then
    echo "ERROR: missing <$arg>."
    echo "Usage: ./run_ori.sh -s <script_name> -o <origin> -p <project_dir> -d <data_per_core> -c <cores> [-h <hold_jid>]"
    exit 1
  elif [ "$arg" == "origin" ]; then
    check_args "${valid_ori[*]}" "$origin"
  fi
done

# determine number of tasks
if [ "$origin" == "all" ]; then
  total_samples=1
else
  declare -i total_samples=$(wc -l < ${project_dir}/samples/${origin}_samples.txt)
fi

job_name=$(echo $script_name | cut -d '/' -f 2-)
joblogs_output="$SCRATCH/joblogs/$origin/"
array_string="1-$total_samples%8"  # limit to 8 concurrent array jobs

# submit job
if [ -z "${hold_jid:-}" ]; then
  jobid=$(qsub \
    -cwd \
    -N "${origin}.${job_name}" \
    -o $joblogs_output \
    -j y \
    -l h_rt=24:00:00,h_data=${data_per_core}G \
    -pe shared ${cores} \
    -M $USER@mail \
    -m ea \
    -terse \
    -t $array_string \
    $script_name "$origin" "$project_dir" "$cores")
else
  jobid=$(qsub \
    -cwd \
    -N "${origin}.${job_name}" \
    -o $joblogs_output \
    -j y \
    -l h_rt=24:00:00,h_data=${data_per_core}G \
    -pe shared ${cores} \
    -M $USER@mail \
    -m ea \
    -hold_jid $hold_jid \
    -terse \
    -t $array_string \
    $script_name "$origin" "$project_dir" "$cores")
fi

# return job ID to run_step.sh
echo "$jobid"
