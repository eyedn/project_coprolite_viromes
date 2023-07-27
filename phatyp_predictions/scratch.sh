# TODO: test manual
cd software/PhaBOX/
module load python
source $HOME/my_py/bin/activate
module load anaconda3
conda activate phabox

gunzip $SCRATCH/project_coprolite_viromes/contigs/pal-BEL_SRS510175_assembly/pal-BEL_SRS510175_all_contigs.fa.gz
python3 PhaMer_single.py --contigs $SCRATCH/project_coprolite_viromes/contigs/pal-BEL_SRS510175_assembly/pal-BEL_SRS510175_all_contigs.fa --threads 8 --len 100 --rootpth $SCRATCH/project_coprolite_viromes/lifestyle/pal-BEL_SRS510175_prediction
gzip $SCRATCH/project_coprolite_viromes/contigs/pal-BEL_SRS510175_assembly/pal-BEL_SRS510175_all_contigs.fa
python3 PhaTYP_single.py --contigs $SCRATCH/project_coprolite_viromes/contigs/pal-BEL_SRS510175_assembly/pal-BEL_SRS510175_viral_contigs.fa --threads 8 --len 100 --rootpth $SCRATCH/project_coprolite_viromes/lifestyle/pal-BEL_SRS510175_prediction
python3 PhaTYP_single.py --contigs $SCRATCH/project_coprolite_viromes/lifestyle/pal-BEL_SRS510175_prediction/predicted_phage.fa  --threads 8 --len 100 --rootpth $SCRATCH/project_coprolite_viromes/lifestyle/pal-BEL_SRS510175_prediction