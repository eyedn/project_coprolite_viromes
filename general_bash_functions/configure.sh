#!/bin/bash
###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       configure.sh 
###############################################################################


software="$HOME/software"

prefetch="$software/sratoolkit.3.0.5-ubuntu64/bin/prefetch-orig.3.0.5"

fasterq_dump="$software/sratoolkit.3.0.5-ubuntu64/bin/fasterq-dump-orig.3.0.5"

trim_galore="$software/TrimGalore-0.6.10/trim_galore"

bowtie2="$software/bowtie2-2.5.1-linux-x86_64/bowtie2"

hmmsearch="$software/hmmer-3.3.2/src/hmmsearch"

hmmbuild="$software/hmmer-3.3.2/src/hmmbuild"

esl_reformat="$software/hmmer-3.3.2/src/esl_reformat"

megahit="$software/MEGAHIT-1.2.9-Linux-x86_64-static/bin/megahit"

python_env="$HOME/my_py/bin/activate"

hum_genome_ref="$HOME/references/GRCh38_noalt_as"

phabox="$software/PhaBOX"

ref_db="$HOME/references"

fasterq_dump_cores=6

trim_galore_cores=6
