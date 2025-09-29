#!/bin/bash

###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       source_tracker.sh
###############################################################################
#$ -cwd
#$ -N st2
#$ -o /u/scratch/a/ayd1n/joblogs/sourcetracker/
#$ -j y
#$ -l h_data=8G,h_rt=24:00:00
#$ -pe shared 8

# to run: qsub source_tracker.sh

set -euo pipefail
source /u/local/Modules/default/init/modules.sh
module purge
ml anaconda3 jq/1.7.1
conda activate st2

cd /u/scratch/b/bwknowle/project_coprolite_viromes/sourcetracker
mkdir -p sourcetracker sourcetracker_output

# ensure jq/biom/sourcetracker2 are available
command -v jq >/dev/null 2>&1 || { echo "ERROR: jq not found in PATH"; exit 1; }
command -v biom >/dev/null 2>&1 || { echo "ERROR: biom not found in PATH"; exit 1; }
command -v sourcetracker2 >/dev/null 2>&1 || { echo "ERROR: sourcetracker2 not found in PATH"; exit 1; }

echo "Converting MetaPhlAn BIOM JSON -> HDF5 with consistent sample IDs"
shopt -s nullglob
rm -f *.biom *.json.biom merged.biom biom.samples map.samples

for f in *_fastq_clean_profile.txt; do
    sid="${f%_fastq_clean_profile.txt}"          # desired sample ID
    jtmp="${sid}.json.biom"
    hout="${sid}.biom"

    # 1) force the BIOM column (sample) id to sid
    jq --arg sid "$sid" '.columns[0].id = $sid' "$f" > "$jtmp"

    # 2) validate JSON BIOM
    biom validate-table -i "$jtmp"

    # 3) convert JSON -> HDF5 (set table type explicitly)
    biom convert -i "$jtmp" --input-format JSON --to-hdf5 -o "$hout" \
        --table-type "OTU table"
done

echo "Merging individual BIOMs -> merged.biom"
biom merge -i *.biom -o merged.biom

echo "Creating mapping.txt"
{
    printf "#SampleID\tSourceSink\tEnv\n"
    for f in *_fastq_clean_profile.txt; do
    sid="${f%_fastq_clean_profile.txt}"
    case "$sid" in
        ind-*)  printf "%s\tsource\tind\n"  "$sid" ;;
        pre-*)  printf "%s\tsource\tpre\n"  "$sid" ;;
        soil-*) printf "%s\tsource\tsoil\n" "$sid" ;;
        pal-*)  printf "%s\tsink\tpal\n"    "$sid" ;;
        *)      : ;;
    esac
    done | sort -u
} > mapping.txt

echo "Sanity check: BIOM sample IDs vs mapping SampleIDs"
biom show-samples -i merged.biom | sort > biom.samples
grep -v '^#' mapping.txt | cut -f1 | sort > map.samples
echo "In BIOM not in mapping:"
comm -23 biom.samples map.samples || true
echo "In mapping not in BIOM:"
comm -13 biom.samples map.samples || true

echo "running SourceTracker2 (Gibbs)"
sourcetracker2 gibbs \
    -i merged.biom \
    -m mapping.txt \
    --source_column SourceSink \
    --source_category Env \
    -o sourcetracker_output/ \
    --jobs 8

echo "Done."
