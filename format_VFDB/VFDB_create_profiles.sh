#!/bin/bash
source /u/local/Modules/default/init/modules.sh
module load anaconda3
conda activate msa


# define number of cores to use arguments
cores=$1

# define directories for the output files and input fasta
PROTEIN_DIR="$SCRATCH/VFDB_proteins"
ALIGN_DIR="$SCRATCH/VFDB_align"
PROFILE_DIR="$SCRATCH/VFDB_profiles"
FILE=$(head -n ${SGE_TASK_ID} $SCRATCH/VFDB_clusters/clusters.txt | tail -n 1)

# create directories if they don't exist
mkdir -p "$PROTEIN_DIR"
mkdir -p "$ALIGN_DIR"
mkdir -p "$PROFILE_DIR"

# run mafft on fasta file
ALN=$(echo $FILE | sed 's/.fasta/.aln/')
mafft --auto --thread $cores $FILE > $ALN

# Run hmmbuild on aligned fasta file to produce profile
software="$HOME/software"
hmmbuild="$software/hmmer-3.4/src/hmmbuild"
HMM=$(echo $FILE | sed 's/.aln/.hmm/')
$hmmbuild --amino --cpu $cores $HMM $ALN

# check if hmm file was created and has content
if [ ! -s "$HMM" ]; then
    echo $HMM >> $SCRATCH/VFDB_profile_errors.txt
    exit 1
else
    rm -rf $SCRATCH/joblogs/create_profiles/*.${SGE_TASK_ID}
fi
