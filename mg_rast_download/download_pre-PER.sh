###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		download_pre-PER.sh 
###############################################################################
#!/bin/bash
. $HOME/project_coprolite_viromes/mg_rast_download/mg_rast_auth_key.sh

curl -X GET -H "auth: $auth_key" "https://api.mg-rast.org/download/mgm${id}?file=299.1" > ${id_path}/FASTA/${id}.fasta