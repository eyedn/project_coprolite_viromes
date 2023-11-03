#!/bin/bash
source /u/local/Modules/default/init/modules.sh
module load anaconda3
conda activate msa


# Define arguments
NTH=$SGE_TASK_ID
FILE=$1
cores=$2

# Directories for the output files
PROTEIN_DIR="$SCRATCH/VFDB_proteins"
ALIGN_DIR="$SCRATCH/VFDB_align"
PROFILE_DIR="$SCRATCH/VFDB_profiles"

# Create directories if they don't exist
mkdir -p "$PROTEIN_DIR"
mkdir -p "$ALIGN_DIR"
mkdir -p "$PROFILE_DIR"

# Extract the label from the FASTA file
label=$(awk -v N="$NTH" 'BEGIN {n_seq=0} /^>/ {if(++n_seq==N) {print; exit}}' "$FILE")

# Format the label into a filename-friendly format
profile_name=$(echo "$label" | sed 's/>//1; s/) .*//1; s/(\||/_/g')

# Use awk to parse the nth sequence and save it to the new file using profile_name for the filename
awk -v N="$NTH" -v PROTEIN_DIR="$PROTEIN_DIR" -v profile_name="$profile_name" '
  BEGIN {n_seq=0; out_file=""}
  /^>/ {
    if(n_seq==N) {exit}
    if(++n_seq==N) {
      out_file=sprintf("%s/%s.fas", PROTEIN_DIR, profile_name);
      print_it=1;
    }
  }
  {if(print_it) print > out_file}
' "$FILE"

# Run MAFFT on the new FASTA file and save the output using profile_name for the filename
mafft --auto --thread $cores "$PROTEIN_DIR/${profile_name}.fas" > "$ALIGN_DIR/${profile_name}.aln"

# Run HMMBUILD on aligned FASTA file to produce profile
software="$HOME/software"
hmmbuild="$software/hmmer-3.4/src/hmmbuild"
$hmmbuild --amino --cpu $cores "$PROFILE_DIR/${profile_name}.hmm" "$ALIGN_DIR/${profile_name}.aln"

# Check if the file was created and has content
if [ ! -s "$PROFILE_DIR/${profile_name}.hmm" ]; then
    echo $label >> $SCRATCH/VFDB_profile_errors.txt
    exit 1
else
    rm -rf $SCRATCH/joblogs/create_profiles/*.$NTH
fi
