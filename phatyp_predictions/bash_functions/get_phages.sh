###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		get_phages.sh 
###############################################################################
#!/bin/bash
cd $HOME/project_coprolite_viromes
for FILE in general_bash_functions/* ; do source $FILE ; done
source /u/local/Modules/default/init/modules.sh
module load python
source $python_env
module load anaconda3
conda activate phabox



# identify which contigs are of phages
