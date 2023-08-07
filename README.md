# Project Coprolite Viromes
The script in the repo compose the bioinformatic pipeline used to collect and
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

## general_bash_functions

## pipeline_by_origin

## pipeline_all

## download

## megahit_assembly

## prokka_annotations

## phabox_predictions

## hmm_alignment

## data_wrangling

## analysis