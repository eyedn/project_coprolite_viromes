#!/bin/bash
source /u/local/Modules/default/init/modules.sh
module load anaconda3
conda activate msa


# define number of cores to use arguments
cores=$1

# input fasta
FAS=$(head -n ${SGE_TASK_ID} $SCRATCH/VFDB_cluster_profiles/clusters.txt | tail -n 1)

# run mafft on fasta file
ALN=$(echo $FAS | sed 's/.fasta/.aln/')
mafft --auto --thread $cores $FAS > $ALN

# Run hmmbuild on aligned fasta file to produce profile
software="$HOME/software"
hmmbuild="$software/hmmer-3.4/src/hmmbuild"
ALN=$(echo $FILE | sed 's/.aln/.hmm/')
$hmmbuild --amino --cpu $cores $HMM $ALN

# check if hmm file was created and has content
if [ ! -s "$HMM" ]; then
    echo $HMM >> $SCRATCH/VFDB_profile_errors.txt
    exit 1
else
    rm -rf $SCRATCH/joblogs/create_profiles/*.${SGE_TASK_ID}
fi
