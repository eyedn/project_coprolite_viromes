# Project Coprolite Viromes
The scripts in this repository comprise the bioinformatic pipeline used to 
collect and analyze publicly available human gut metagenomic sequence data. 
Samples in this project were from modern-industrial, modern-non-industrial, and 
paleofecal samples, known as coprolites. The pipeline can be run in a Linux 
environment. Statistical analysis and visualization were performed in an .Rmd 
file.

## Overview of Pipeline
The pipeline follows 6 major steps:
1. Download and Assembly
2. Viral Gene Annotation
3. Predictions of Viral Characteristics
4. Bacterial Gene Annotation on Viruses
5. Align Phage Proteins to Databases
    + Virulence Factors
    + Carbohydrate Active Enzymes
Files that govern these steps can be found in the `pipeline` directory, 
distinguished by the file name template `{number}_{name}.sh`

Each major step is associated with an auxiliary step to extract additional data 
needed for analysis. These auxiliary files are distinguished by the file name 
template `{number}a_{name}.sh`, and can be run once the major step file has 
run.

The one exception to this rule is step **(3.)**. The auxiliary file calls on 
"sub-auxiliary" data wrangling steps, distinguished by the file name prefix 
`3b_{number}...`. Running `3a_...` will complete all necessary sub-auxiliary
steps, but they could be directly run in any order if desired.

## Description of Pipeline Files and Directories in `main`
The step(s) each directory is associated with are provided in "[]" at the end 
of the subsection header.

### `./run_step.sh` [General/All]
`run_step.sh` is used to run samples from all origins through a given pipeline 
step, whether major of auxilliary. The pipeline step to be run is designated
as the one and only argument for this script. Here are the usage instructions
for `run_step.sh`.
```
./run_step.sh pipeline/<script>.sh
```

### `./run_ori.sh` [General/All]
`run_ori.sh` is used to submit sections of the pipeline in the `pipeline` directory 
on the UCLA Hoffman2 Cluster as a job array. `run.sh` requires specifying the 
"origin" of samples (`-o`). Valid origins are:
* Industrial samples: ind-DNK ind-ESP ind-USA
* Non-industrial samples: pre-FJI pre-MDG pre-MEX pre-PER pre-TZA
* Ancient samples: pal-AWC pal-BEL pal-BMS pal-ENG pal-ZAF pal-ZAP
* Misc: test all
In particular, the "all" origin is used when submitting auxiliary steps, since
these steps are not specific to an origin. However, auxilliary steps should
still be done through `run_step.sh`. Here are the usage instructions for 
`run_ori.sh`.
```
./run.sh -p <project_directory> -d <data_per_core> -c <cores> -s <script> -o <sample_origin>
```

### `./samples/` [General/All]
The `samples` directory contains copies of all samples across all origin 
categories. A copy of this directory exists in the directory where files are 
\generated by this pipeline. That is the crucial copy for this pipeline's 
function.

### `./general_bash_functions/` [General/All]
The `general_bash_functions` directory contains general functions and 
`configure.sh`.

### `./pipeline/` [General/All]
The `pipeline` directory contains the 5 main steps in the pipeline that each 
sample must individually go through. It also contains the auxiliary steps that 
can be completed once all samples have completed the associated major step. 
Here are the naming conventions again:
* Major step: all sample origins run individually
    + `./pipeline/{number}_{name}.sh`
* Auxiliary step: all sample origins run together with `-o all`
    + `./pipeline/{number}a_{name}.sh`
* Sub-auxiliar functions for step **(3.)** in `./pipeline/3a_supplement`
    + `./pipeline/3a_supplement/{number}b_{number}_{name}.sh`

### `./download/` [1]
The `download` directory contains scripts that use *prefetch* and 
*fasterq-dump* from the *SRA-Toolkit* to download all accession runs for a 
given sample. Adapter trimming and quality control are performed with the tool 
*Trim Galore*. Further host removal was performed with the tool *Bowtie2*, by 
aligning trimmed reads to a reference human genome (GRCH38_noalt_as) and 
retaining unaligned reads for further processing. For paired reads, both reads 
must align to the reference genome for that pair to be discarded. If only one 
read of the pair aligns, both reads will be retained for further processing.

### `./megahit_assembly/` [1]
The `megahit_assembly` directory contains scripts that use *MEGAHIT* to perform 
de novo metagenomic assembly of reads after download and quality control. 
Scripts involved in library preparation are also found here, as many scripts 
had multiple accession runs that contained both paired and unpaired reads.

### `./prokka_annotations/` [2,3,4]
The `prokka_annotations` directory contains scripts that use *Prokka* for 
genome annotation. Scripts that identify which assembled contigs contain a 
viral gene annotation are also found here.

### `./phabox_predictions/` [3]
The `phabox_predictions` directory contains scripts that use the tools under 
*PhaBox* to perform phage contig identification, viral lifestyle prediction, 
viral taxonomic family prediction, and host prediction.

### './hmm_alignment/' [5]
The `hmm_alignment` directory contains scripts that align predicted phage
proteins to data bases with `HMMER`. The 2 data bases in question are:
* Virulence Factor (VF)
    + Liu B, Zheng D, Zhou S, Chen L, Yang J. VFDB 2022: a general classification scheme for bacterial virulence factors. Nucleic Acids Res. 2022 Jan 7;50(D1):D912-D917. doi: 10.1093/nar/gkab1107. PMID: 34850947; PMCID: PMC8728188.  
* Carbohydrate Active Enzymes (CAZY)
    + Elodie Drula, Marie-Line Garron, Suzan Dogan, Vincent Lombard, Bernard Henrissat, Nicolas Terrapon, The carbohydrate-active enzyme database: functions and literature, Nucleic Acids Research, Volume 50, Issue D1, 7 January 2022, Pages D571–D577, https://doi.org/10.1093/nar/gkab1045.
An HMM profile of clustered CAZY proteins was already provided. Construction 
of an HMM profile of clusted VF proteins was performed by clustering VF by
their VFID (designation made by VF Data Base). Predicted phage proteins were 
generated by annotating phage contigs for bacterial genes in step **(3.)**.

### `./data_wrangling/` [All Auxiliary Steps]
The `data_wrangling` directory contains scripts that collect raw counts and 
meta information after a major step is completed. These are the scripts used by 
the auxiliary steps of the pipeline.

## Overview of Statistical Analysis
The `analysis` directory holds all files used to analyze the outputs of the 
pipeline. The file used to perform statistical tests, learning methods, and 
create visuals is `analysis/analysis.Rmd`.
