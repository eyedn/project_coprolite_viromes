# Project Coprolite Viromes
The scripts in this repository comprise the bioinformatic pipeline used to 
collect and analyze publicly available human gut metagenomic sequence data. 
Samples in this project were from modern-industrial, modern-non-industrial, and 
paleofecal samples, known as coprolites. The pipeline can be run in a Linux 
environment. Statistical analysis and visualization were performed in an .Rmd 
file. NOTE: Associated paper lables historical periods as pre-historic,
non-industrial modern, and industrial modern. Prefixes for variables and files
in this pipeline use "pal" for pre-historic, "pre" for non-industrial modern,
and "ind" for industial modern. The written paper does not use these
conventions.

## Overview of Pipeline

The supported analysis workflow has four major stages:

1. Download and assemble: `pipeline/1_download_and_assembly.sh`
2. Predict phage characteristics and annotate phage contigs:
   `pipeline/2_predict_viral_character.sh`
3. Align phage proteins to VFDB: `pipeline/3_align_phages_to_dbs.sh`
4. Analyze complete CheckV genomes for both trimming filters:
   `pipeline/4_analyze_checkv_genomes.sh`

Run each major stage for every included origin with `run_step.sh`, completing
the stages in order. After stage 2 has completed for all origins, run
`pipeline/2a_get_prediction_counts.sh` with the `all` origin. It produces
`lifestyle_counts.csv`, `bac_on_phage_ec_counts.csv`, and
`vir_on_phage_ec_counts.csv`; the latter is retained even though the active
report does not currently consume it. Its supporting scripts are in
`pipeline/2a_supplement/` and use the `2b_{number}_...` name pattern.

Stages 3 and 4 search **every bacterial-mode Prokka FAA protein**, joining
exact FAA identifiers to GFF CDS identifiers. Hypothetical proteins, EC-labeled
proteins, named proteins without EC numbers, and hypothetical proteins with EC
numbers all enter the search pool. Complete existing Prokka outputs are reused without modifying or recompressing
them. Stage 2 (`pipeline/2_predict_viral_character.sh`) and its PhaBOX/Prokka
helper logic are unchanged; this migration begins at VFDB search and
downstream aggregation.
Duplicates, unmatched FAA/GFF identifiers, invalid coordinates, and unknown
HMMER targets fail validation. Biological no-phage and zero-FAA stage-3 skips
and alignment QC exclusions remain in effect.

Both stages retain their three-argument interfaces and search these references
independently, using the existing `hmmsearch --incE 1e-5` arguments:

* `${ref_db}/VFDB_setA_pro_20230917.txt`
* `${ref_db}/VFDB_setB_pro_20260923.txt`

Raw `table.txt` and `results.txt` are retained in new directories, separate from
historical searches:

* Contigs: `alignment/vfdb_all_orfs/<version>/<sample>_vf/`, where `<sample>`
  is the existing `<origin>_<sample_id>` label.
* CheckV: `checkv_genomes/<filter>/vf_alignment_all_orfs/<version>/`.

`<version>` is `VFDB_setA` or `VFDB_setB`. A `search_manifest.json` records the
full-pool marker, exact protein count, FAA and database SHA-256 digests, and
sample/filter search scope. Cached searches require both complete HMMER outputs
ending in `[ok]`, matching provenance, and valid target identifiers. Partial or
stale cached outputs fail; move them aside before rerunning that search.

After stage 3 has completed for all origins, run
`pipeline/3a_get_alignment_counts.sh` with the `all` origin. Each version
publishes the following files under `data/`:

* `all_vf_hits.csv`: raw combined HMMER rows.
* `phage_vf_orfs.csv`: every bacterial ORF, including non-hit ORFs.
* `phage_vf_stats.csv`: per-contig qualifying counts and interval-union coverage.
* `sample_vf_stats.csv`: pooled sample counts, prevalence, and coverage.
* `phage_vf_stats_qc.csv` and `vf_alignment_qc.csv`: aggregation and search QC.
* `vf_alignment_counts.csv` and `vf_alignment_contig_hits.csv`: legacy
  E-value-only diagnostics; these are not scientific prevalence inputs.

Set B uses the filenames above. Set A inserts `_VFDB_setA` before `.csv` for
all products, including `phage_vf_orfs_VFDB_setA.csv` and
`sample_vf_stats_VFDB_setA.csv`.

Step 4 is filter-specific rather than sample-origin-specific. `run_step.sh`
submits one single-task job named `checkv-conservative` and one named
`checkv-aggressive`. Each job reads the following immutable inputs:

* `checkv_input/<filter>/genomes.fa.gz`
* `checkv_input/<filter>/quality_summary.tsv`
* `checkv_input/<filter>/complete_contigs.txt`

PhaTYP, PhaGCN, raw bacterial and viral Prokka results, filtered annotation-map
features, and VFDB search results are written under `checkv_genomes/<filter>/`.
Filtered bacterial/viral map features still require an EC number and a
non-hypothetical product. This display subset does **not** restrict the VFDB
search pool. VF map features include every qualifying bacterial ORF, including
hypothetical and non-EC proteins.

After both filter jobs finish, run
`pipeline/4a_get_checkv_genome_stats.sh`. It validates both filters independently
for both reference versions and publishes these six files under `data/`:

* `checkv_genome_metadata.csv`
* `checkv_genome_features.csv`
* `checkv_genome_vf_hits.csv`
* `checkv_genome_vf_stats.csv`
* `checkv_genome_orfs.csv`
* `checkv_genome_qc.csv`

Set A uses `_VFDB_setA.csv` suffixes; set B is unsuffixed. The ORF inventories
retain sample, contig/genome, ORF ID, coordinates, strand, Prokka product, EC
number, independent `is_hypothetical`/`has_ec_number` flags, and the best
qualifying VFDB hit and scores. Non-hit ORFs have blank hit fields. ORF
inventories and scientific summaries identify `vfdb_version` and
`orf_pool = all_bacterial_prokka_cds`.

Scientific counts apply full-sequence **E-value ≤ 1e-10, score ≥ 25, and
score ≥ 10 × bias**, retaining the existing deterministic best qualifying hit
per ORF. An ORF counts once. Summaries include total and qualifying ORFs,
hypothetical and EC-labeled totals/hits, and their intersection. These allow
annotation-overlap queries without restricting the original search.

`vf_orf_prevalence = qualifying_vf_orfs / total_bacterial_orfs`. Positive
ORF totals with no hits give zero; zero denominators give missing prevalence.
Sample prevalence pools counts across contigs. Coverage retains the union of
qualifying full-CDS intervals per contig and pooled covered/total contig bases
per sample. CheckV summaries use `total_bacterial_orfs` in place of the old
`eligible_bacterial_orfs` field.

The contig report runs separate set A/B analyses and writes plots and CSV
exports under `figures/VFDB_setA/` and `figures/VFDB_setB/`. Sample prevalence
and eligibility come from `sample_vf_stats`; setup exposes
`MIN_TOTAL_ORFS <- 5L` and retains samples with totals **greater than** that
value. Existing bootstrap, downsampling, coverage, and differential
representation methods remain. Qualifying VFDB IDs without reference metadata
remain in hit-count and differential-representation tables. The denominator
label is “Qualifying VFDB-hit ORFs / all Prokka ORFs”; these are bacterial-mode
calls on predicted phage contigs.

The CheckV report consumes regenerated full-pool products and analyzes only
conservative trimming, while retaining shared set A/B lifestyle facets and
panel-specific means. PhaGCN plots remain commented. Its external selected
network-contig analysis remains explicitly historical. Both active reports
reject missing or incompatible pool/version markers.

Rerun order: validate representative Hoffman2 searches for both databases,
complete stages 3 and 4 (both references and both CheckV filters), complete
stages 3a and 4a, copy regenerated products to the report's configured
`data_dir`, then render the reports. Historical restricted-pool results must
not be relabeled or activated as full-pool results.

`pipeline/1a_get_combined_contig_stats.sh` is optional assembly/QC metadata;
it is not required for the active analysis workflow.

### External and manual analysis prerequisites

The active report reads all inputs from its configured local `data_dir`. Copy
the following external/manual inputs into that directory before rendering:

* SourceTracker output in `sourcetracker_output/`, including
  `mixing_proportions.txt` and `mixing_proportions_stds.txt`.
* VFDB metadata as `VFs.csv`.
* Selected-network-contig inputs: `proteins_all_ids.txt`,
  `proteins_best_ids.txt`, and `proteins_all_hits_formatted.csv`.

## Description of Pipeline Files and Directories in `main`
The associated pipeline stage is shown in brackets at the end of each heading.

### `./run_step.sh` [General/All]
`run_step.sh` is the supported launcher for pipeline entrypoints. It accepts
one script path:

```
./run_step.sh pipeline/<script>.sh
```

For stages 1--3, it prompts for a sample group and submits one job array for
each origin in that group. For auxiliary scripts with a `{number}a_` prefix,
it submits a single `all` job. Stage 4 is a special case: it submits one
single-task job for each CheckV filter, `checkv-conservative` and
`checkv-aggressive`.

### `./run_ori.sh` [General/All]
`run_ori.sh` is the lower-level Hoffman2 submission wrapper used by
`run_step.sh`. It submits a job array for an individual origin, or a
single-task job for `all` and filter-specific CheckV origins. Its valid sample
origins include paleofecal (`pal-*`), industrial (`ind-*`), and non-industrial
(`pre-*`) origins, as well as the source/soil controls. Use `run_step.sh` for
the supported workflow rather than calling this wrapper directly.

```
./run_ori.sh -p <project_directory> -d <data_per_core> -c <cores> \
    -s <script> -o <origin>
```

### `./samples/` [General/All]
The `samples` directory contains per-origin sample manifests. The corresponding
copy in the processing project directory determines the samples submitted by
the workflow.

### `./general_bash_functions/` [General/All]
The `general_bash_functions` directory contains shared shell helpers and
`configure.sh`.

### `./pipeline/` [General/All]
The `pipeline` directory contains the supported entrypoints. Run stages 1--3
for each included sample origin, then run their corresponding aggregates with
the `all` origin. Stage 4 instead runs once for each CheckV trimming filter,
followed by its `all` aggregate.

* Stage 1: `1_download_and_assembly.sh`
* Optional stage-1 QC aggregation: `1a_get_combined_contig_stats.sh`
* Stage 2: `2_predict_viral_character.sh`
* Stage-2 aggregation: `2a_get_prediction_counts.sh`
* Stage 3: `3_align_phages_to_dbs.sh`
* Stage-3 VFDB aggregation: `3a_get_alignment_counts.sh`
* Stage 4: `4_analyze_checkv_genomes.sh`
* Stage-4 CheckV aggregation: `4a_get_checkv_genome_stats.sh`

The retained `pipeline/2a_supplement/2b_*` helpers are called by the stage-2
aggregate; they are not separate workflow stages.

### `./download/` [1]
The `download` directory contains scripts that download SRA runs with
`prefetch` and `fasterq-dump`, perform adapter trimming and quality control
with Trim Galore, and remove human reads with Bowtie2. For paired reads, a pair
is discarded only when both reads align to the human reference.

### `./megahit_assembly/` [1]
The `megahit_assembly` directory assembles cleaned reads with MEGAHIT and
prepares the contig FASTA used by later contig-level stages. Eligible
paleofecal assemblies run PyDamage; `pal-AWC`, `pal-BMS`, `pal-ZAP`, and all
non-paleofecal origins do not. For a PyDamage-eligible assembly, the workflow
retains an unfiltered backup,
`<origin>_<sample>_all_contigs.fa.unfiltered.fa`, and writes the filtered
`<origin>_<sample>_all_contigs.fa` consumed by stages 2 and 3. PyDamage results
are retained under the assembly's `pydamage/` directory.

### `./prokka_annotations/` [2]
The `prokka_annotations` directory annotates predicted phage contigs with
Prokka for bacterial and viral gene calls. Stage 3 uses the bacterial-on-phage
annotations when it evaluates VFDB hits.

### `./phabox_predictions/` [2]
The `phabox_predictions` directory runs PhaBOX tools for phage-contig
identification, lifestyle prediction, family prediction, and host prediction.

### `./hmm_alignment/` [3]
The `hmm_alignment` directory runs the active VFDB HMM alignment for proteins
from bacterial-on-phage Prokka annotations. The CAZy alignment helper remains
in this directory but is not called by the active stage-3 entrypoint.

### `./data_wrangling/` [All Auxiliary Steps]
The `data_wrangling` directory contains the aggregation utilities used by
stages 1a, 2a, 3a, and 4a. These include contig metadata collection,
prediction-count aggregation, VFDB hit and phage-statistics collection, and
CheckV genome-statistics validation and aggregation. It also retains helpers
for historical analyses that are not active pipeline entrypoints.

### `./source_tracking/` [Manual QC/Analysis]
The `source_tracking` directory is a separate manual prerequisite, not a
`run_step.sh` stage. Its `get_biom.sh` script runs MetaPhlAn for cleaned reads;
the documented follow-up commands merge profiles, retain species-level taxa,
create a BIOM table and mapping file, and run SourceTracker2. After this manual
workflow completes, copy its `sourcetracker_output/` directory, including
`mixing_proportions.txt` and `mixing_proportions_stds.txt`, into the active
report's `data_dir` before rendering.

## Overview of Statistical Analysis

The `analysis` directory holds the reports and their statistics, graphing,
and miscellaneous helpers:

* `analysis/analysis_contigs.Rmd` is the active contig-level report.
* `analysis/analysis_checkvhits.Rmd` contains the original selected-network
  analysis and the complete CheckV-genome analysis. Its selected-genome map
  accepts `selected.genome.id` and `selected.annotation`; the latter must be
  `viral`, `bacterial`, or `vf`.
* `analysis/analysis_before_phage_vf_stats.Rmd` is a preserved historical
  report and is not part of the active workflow.
