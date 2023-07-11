###############################################################################
#     Aydin Karatas
#		  Project Coprolite Viromes
#		  run_pipeline_all.sh 
###############################################################################
#!/bin/bash
for FILE in general_bash_functions/* ; do source $FILE ; done
cd $home_dir


./run_pipeline.sh -s run_multi_step/download_to_full_annotation.sh  -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o ind-USA
./run_pipeline.sh -s run_multi_step/download_to_full_annotation.sh  -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o ind-ESP
./run_pipeline.sh -s run_multi_step/download_to_full_annotation.sh  -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o ind-DNK
./run_pipeline.sh -s run_multi_step/download_to_full_annotation.sh  -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o pre-PER
./run_pipeline.sh -s run_multi_step/download_to_full_annotation.sh  -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o pre-TZA
./run_pipeline.sh -s run_multi_step/download_to_full_annotation.sh  -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o pre-MEX
./run_pipeline.sh -s run_multi_step/download_to_full_annotation.sh  -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o pre-FJI
./run_pipeline.sh -s run_multi_step/download_to_full_annotation.sh  -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o pre-MDG
./run_pipeline.sh -s run_multi_step/download_to_full_annotation.sh  -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o pal-BEL
./run_pipeline.sh -s run_multi_step/download_to_full_annotation.sh  -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o pal-AWC
./run_pipeline.sh -s run_multi_step/download_to_full_annotation.sh  -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o pal-BMS
./run_pipeline.sh -s run_multi_step/download_to_full_annotation.sh  -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o pal-ENG
./run_pipeline.sh -s run_multi_step/download_to_full_annotation.sh  -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o pal-ZAF
./run_pipeline.sh -s run_multi_step/download_to_full_annotation.sh  -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o pal-ZAP
