###############################################################################
#     Aydin Karatas
#		  Project Coprolite Viromes
#		  submit.sh 
###############################################################################
#!/bin/bash
for FILE in $HOME/project_coprolite_viromes/general_bash_functions/* ; do source $FILE ; done


# paleo samples labeled as pal-{location} :
#       pal-AWC pal-BEL pal-BMS pal-ENG pal-ITA pal-PER pal-ZAF pal-ZAP
# industrial samples labeled as ind-{location} :
#       ind-DNK ind-ESP ind-USA
# pre-industrial samples labeled as pre-{location} :
#       pre-FJI pre-MDG pre-MEX pre-PER pre-TZA
valid_ori=( pal-AWC pal-BEL pal-BMS pal-ENG pal-ITA pal-PER pal-ZAF pal-ZAP \
            ind-DNK ind-ESP ind-USA \
            pre-FJI pre-MDG pre-MEX pre-PER pre-TZA \
            test )
            
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
  if [ -z "${!arg}" ]; then
    echo "ERROR: missing <$arg>."
    echo "Usage Instructions: ./run_pipeline.sh -s <script_name> -o <origin> -p <project_dir> -d <data_per_core> -c <cores>"
    exit 1
  # check orgin name to be in the list of valid origins
  elif [ "$arg" == "origin" ]; then
    check_args "${valid_ori[*]}" "$origin"
  fi
done

# run the submission command on hoffman2
declare -i total_samples=$(wc -l < ${project_dir}/samples/${origin}_samples.txt) 
job_name=$(echo $script_name | cut -d '/' -f 2-)
qsub \
    -cwd \
    -N "${origin}.${job_name}" \
    -o $HOME/joblogs/$origin/ \
    -j y \
    -l h_rt=24:00:00,h_data=${data_per_core}G \
    -pe shared ${cores} \
    -M $USER@mail \
    -m ea \
    -t 1-$total_samples:1 \
    $script_name "$origin" "$project_dir" "$cores"
