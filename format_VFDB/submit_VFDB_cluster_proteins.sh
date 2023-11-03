#!/bin/bash
source /u/local/Modules/default/init/modules.sh
module load python
module load anaconda3
conda activate msa


echo "clustering proteins"
cd-hit \
    -i $SCRATCH/reference_fas/VFDB_setB_pro.fas \
    -o $SCRATCH/reference_fas/VFDB_clusters \
    -c 0.9 \
    -n 5
# Check if the file was created and has content
if [ ! -s "$SCRATCH/reference_fas/VFDB_clusters.clstr" ]; then
    echo "$SCRATCH/reference_fas/VFDB_clusters.clstr not created"
else 
    echo "$SCRATCH/reference_fas/VFDB_clusters.clstr created"
fi

python3 VFDB_extract_clusters.py \
    $SCRATCH/reference_fas/VFDB_clusters.clstr \
    $SCRATCH/reference_fas/VFDB_setB_pro.fas \
    $SCRATCH/reference_fas