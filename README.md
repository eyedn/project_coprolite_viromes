# Project Coprolite Viromes
The scripts in this repo compose the bioinformatic pipeline used to collect and
analyze publicly available human get metagenomic sequence data. Samples in this
project were from modern-industrial samples, modern-non-industrial samples, and
paleofecal samples, known as coprolites. The files and directories listed in
`main` are descripted below.

## submit_pipeline_by_origin.sh
`submit_pipeline_by_origin.sh` is used to submit sections of the pipeline
listed under `pipeline_by_origin` on the UCLA Hoffman2 Cluster. Pipeline
script submission is performed by
```
./submit_pipeline_by_origin.sh pipeline_by_origin/<script>.sh
```

## submit_script.sh
`submit_script.sh` is used to submit individual scripts that are a part of the
pipeline on the UCLA Hoffman2 Cluster. One application of `submit_script.sh` is
to submit scipts under the directory `pipeline_all`, which contain scripts that
collect raw counts associated with various steps of the pipeline outlined under 
`pipeline_by_origin`. Submission of an individual script
```
./submit_script.sh -p <project_directory> -d <data_per_core> -c <cores> -s <script> -o <sample_origin>
```
## samples
The `samples` directory contains copies of all samples across all origin
categories.

## general_bash_functions
The `general_bash_functions` directory contains general functions and
`configure.sh`.

## pipeline_by_origin
The `pipeline_by_origin` directory contains the 4 mains steps in the pipeline
that each samples must individually go through. Files begin with a number
indicating which step of the pipeline they occur in. Steps 2 and 3 are the
only interchangeable steps.

## pipeline_all
The `pipeline_all` directory contains 8 files associated with the 4 pipeline
steps. Each of the files in this collect data/raw counts from files generated
from the pipeline. Scripts in this directory are not run by individual sample
origins.

## download
The `download` directory contains the scripts that use *prefetch* and
*fasterq-dump* from the *SRA-Toolkit* to download all accession runs for a
given sample. Adpater trimming and quality contol is performed with the tool
*Trim Galore*. Further host removal was performed with the tool *Bowtie2*, by
aligning trimmed reads to a reference human genome (GRCH38_noalt_as) and
retaining unaligned reads for further processing. For paired reads, both reads
must align to the reference genome for that pair to be discarded. If only one
read of the pair aligns, both reads will be retained for further processing.

## megahit_assembly
The `megahit_assembly` directory contains the scripts that use *MEGAHIT* to
perform de novo metageomic assembly of reads after download and quality.
contol. Scripts involved in library preparation are also found here since many
scipts had multple accession runs that contained were paired and/or unpaired
reads.

## prokka_annotations
The `prokka_annotations` directory contains scripts that used *Prokka* for
genome annotation. Scripts that identify which assembled contigs contained a
viral gene annotation are also found here. 

## phabox_predictions
The `phabox_predictions` directory contains scripts that used the tools under
*PhaBox* to perform phage contig identification, viral lifestyle prediction,
viral taxonomic family prediction, and host prediction.

## hmm_alignment
The `hmm_alignment` directory contains scripts that build and align contigs
to databases with `HMMER`.

## data_wrangling
The `data_wrangling` directory contains scripts that collect raw counts of
individual samples and contain functions for raw counts collection. Scripts in
this directory are used by scripts in both `pipeline_by_origin` and 
`pipeline_all`.

## analysis
The `analysis` directory contains scripts that are used in *Rstudio* to perform
data analysis. This includes k-means clustering, differential representation
analysis, and visualization.