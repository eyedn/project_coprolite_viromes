###############################################################################
#     Aydin Karatas
#		  Project Coprolite Viromes
#		  run_pipeline_all.sh 
###############################################################################
#!/bin/bash
cd $HOME/project_coprolite_viromes


./run_single.sh -s pipeline/main.sh  -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o ind-USA
./run_single.sh -s pipeline/main.sh  -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o ind-ESP
./run_single.sh -s pipeline/main.sh  -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o ind-DNK
./run_single.sh -s pipeline/main.sh  -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o pre-PER
./run_single.sh -s pipeline/main.sh  -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o pre-TZA
./run_single.sh -s pipeline/main.sh  -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o pre-MEX
./run_single.sh -s pipeline/main.sh  -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o pre-FJI
./run_single.sh -s pipeline/main.sh  -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o pre-MDG
./run_single.sh -s pipeline/main.sh  -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o pal-BEL
./run_single.sh -s pipeline/main.sh  -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o pal-AWC
./run_single.sh -s pipeline/main.sh  -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o pal-BMS
./run_single.sh -s pipeline/main.sh  -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o pal-ENG
./run_single.sh -s pipeline/main.sh  -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o pal-ZAF
./run_single.sh -s pipeline/main.sh  -d 8 -c 8 -p $SCRATCH/project_coprolite_viromes -o pal-ZAP
