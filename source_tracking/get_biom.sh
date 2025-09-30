#!/bin/bash

###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		get_biom.sh 
###############################################################################
#$ -cwd
#$ -N mpa
#$ -o /u/scratch/a/ayd1n/joblogs/sourcetracker/
#$ -j y
#$ -l h_data=8G,h_rt=24:00:00
#$ -pe shared 8

# to run: qsub -t 1-$(ls -d /u/scratch/b/bwknowle/project_coprolite_viromes/reads/*_fastq_clean | wc -l) get_biom.sh

set -euo pipefail
source /u/local/Modules/default/init/modules.sh
module purge
ml bowtie2/2.4.2
ml anaconda3
conda activate mpa

cd /u/scratch/b/bwknowle/project_coprolite_viromes
mkdir -p sourcetracker

# pick the nth directory
readarray -t dirs < <(ls -d reads/*_fastq_clean)
i="${dirs[$((SGE_TASK_ID-1))]}"

sample="$(basename "$i")"
fastqs="$(
    printf '%s\n' "${i}/"*".fastq.gz" | paste -sd, - 
)"
echo "$sample"

metaphlan "$fastqs" \
    --verbose \
    --nproc 8 \
    --db_dir /u/scratch/b/bwknowle/mpa_db \
    --input_type fastq \
    --mapout "sourcetracker/${sample}.bowtie2.bz2" \
    -o "sourcetracker/${sample}_profile.out"
    # --biom_format_output
