###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		get_lifestyles.sh 
###############################################################################
#!/bin/bash
cd $HOME/project_coprolite_viromes
for FILE in general_bash_functions/* ; do source $FILE ; done
source /u/local/Modules/default/init/modules.sh
module load anaconda3
conda activate phabox
module load python
source $python_env


# use PhaTYP from PhaBOX to predict viral lifestyles
get_lifestyles() {
    local sample=$1
	local contigs_file=$2
	local predict_dir=$3
	local num_cores=$4


    # create predictions dir for this sample
    mkdir -p $predict_dir
    # if the predictions dir already exists, delete its contents
    rm -r $predict_dir/*

    echo "$(timestamp): get_lifestyles: $sample"
	echo "__________________________________________________"
    cd $phabox
    python3 PhaTYP_single.py  \
        --contigs $contigs_file \
        --threads 8 \
        --len 100 \
        --rootpth $predict_dir \
        --dbdir database \
        --midfolder midfolder \
        --out out
    cd $HOME
    echo "__________________________________________________"

    # Check if predictions were completed
	if ls $predict_dir/out/phatyp_prediction.csv 1> /dev/null 2>&1; then
		echo "$(timestamp): get_lifestyles: final contigs file created"
		# Check if the file is empty
		if ! [ -s "$predict_dir/out/phatyp_prediction.csv" ]; then
			echo "$(timestamp): get_lifestyles: ERROR! predictions file is empty"
			exit 1
		fi
	else
		echo "$(timestamp): get_lifestyles: ERROR! predictions file not found"
		exit 1
	fi
}
