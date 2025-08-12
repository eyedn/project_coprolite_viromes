#!/bin/bash
###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       download_and_MetaPhlAn2.sh
###############################################################################
cd "$HOME/project_coprolite_viromes"
for FILE in download/bash_functions/* ; do source "$FILE" ; done
for FILE in general_bash_functions/* ; do source "$FILE" ; done
source "$HOME/project_coprolite_viromes/configure.sh"

# env/modules (MetaPhlAn2 will be run via explicit path below)
source /u/local/Modules/default/init/modules.sh
module load anaconda3
conda activate qc

# define inputs variables
origin=$1
project_dir=$2
num_cores=$3

# define sample variables
sample=$(head -n ${SGE_TASK_ID} "${project_dir}/samples/${origin}_samples.txt" | \
         tail -n 1 | cut -d ' ' -f 1)
accession_ids=$(head -n ${SGE_TASK_ID} "${project_dir}/samples/${origin}_samples.txt" | \
               tail -n 1 | cut -d ' ' -f 2-)

# define directories
reads_dir="${project_dir}/reads"
sra_dir="${reads_dir}/${origin}_${sample}_sra"
fastq_raw_dir="${reads_dir}/${origin}_${sample}_fastq_raw"
fastq_trimmed_dir="${reads_dir}/${origin}_${sample}_fastq_trimmed"
fastq_clean_dir="${reads_dir}/${origin}_${sample}_fastq_clean"
data_dir="${project_dir}/data/read_stats"

# check if download process already was complete for this sample
if ls "${reads_dir}/${origin}_${sample}_DONE.txt" 1> /dev/null 2>&1; then
	echo "$(timestamp): download: ${reads_dir}/${origin}_${sample}_DONE.txt found."
	# Still proceed to MetaPhlAn (allows re-runs of profiling/merge)
else
	for id in $accession_ids; do
		fastq_stats="${data_dir}/${origin}_${sample}_${id}_read_stats.txt"
		fastq_stats_done="${data_dir}/${origin}_${sample}_${id}_read_stats_DONE.txt"
		mkdir -p "$data_dir"
		echo "${origin}_${sample}_${id}" > "$fastq_stats"

		# download sra file for each accession id
		echo "===================================================================================================="
		echo "$(timestamp): download: prefetching sra file: $origin; $sample; $id"
		echo "===================================================================================================="
		download_sra "$id" "$sra_dir"

		# convert sra file to fastq file(s)
		echo "===================================================================================================="
		echo "$(timestamp): download: converting sra file to fastq files: $origin; $sample; $id"
		echo "===================================================================================================="
		# generate_fastq expects: id, sra_dir, fastq_raw_dir, num_cores
		generate_fastq "$id" "$sra_dir" "$fastq_raw_dir" "$num_cores"

		# quality control fastq files by removing adapters and low quality reads
		echo "===================================================================================================="
		echo "$(timestamp): download: quality control fastq files: $origin; $sample; $id"
		echo "===================================================================================================="
		quality_control "$id" "$fastq_raw_dir" "$fastq_trimmed_dir" "$fastq_stats" "$num_cores"

		# remove human reads from fastq files
		echo "===================================================================================================="
		echo "$(timestamp): download: remove human dna from trimmed reads: $origin; $sample; $id"
		echo "===================================================================================================="
		remove_human_reads "$id" "$fastq_trimmed_dir" "$fastq_clean_dir" "$fastq_stats" "$num_cores"

		echo "$(timestamp): download: pre-processing complete for $id"
		mv "$fastq_stats" "$fastq_stats_done"
	done

	touch "${reads_dir}/${origin}_${sample}_DONE.txt"
	echo "$(timestamp): download_and_pre_process: pre-processing complete for $sample"
fi

###############################################################################
# MetaPhlAn2 per-sample profiling + optional merge for SourceTracker v1
###############################################################################

# paths for MetaPhlAn2 
metaphlan_py="$software/MetaPhlAn2/metaphlan2.py"                           
merge_mpa_py="$software/MetaPhlAn2/utils/merge_metaphlan_tables.py"         

echo "===================================================================================================="
echo "$(timestamp): MetaPhlAn2: profiling sample: $origin; $sample"
echo "===================================================================================================="

mpa_out_dir="${project_dir}/data/metaphlan2/${origin}"
mkdir -p "$mpa_out_dir"
prof_tsv="${mpa_out_dir}/${sample}_metaphlan.tsv"
prof_done="${mpa_out_dir}/${sample}_DONE.txt"

if [[ -f "$prof_done" && -s "$prof_tsv" ]]; then
	echo "$(timestamp): MetaPhlAn2: ${sample} already complete -> $prof_tsv"
else
	# Gather cleaned reads for this sample across all accessions
	tmp_dir="${fastq_clean_dir}/__metaphlan_tmp_${sample}"
	mkdir -p "$tmp_dir"
	cat_R1="${tmp_dir}/${sample}_R1.cat.fastq.gz"
	cat_R2="${tmp_dir}/${sample}_R2.cat.fastq.gz"
	cat_SE="${tmp_dir}/${sample}_SE.cat.fastq.gz"

	# find paired & single-end cleaned reads
	mapfile -t R1S < <(ls -1 "${fastq_clean_dir}"/*/*_R1.fastq.gz 2>/dev/null | sort)
	mapfile -t R2S < <(ls -1 "${fastq_clean_dir}"/*/*_R2.fastq.gz 2>/dev/null | sort)
	mapfile -t SES < <(ls -1 "${fastq_clean_dir}"/*/*_RU.fastq.gz 2>/dev/null | sort)

	have_paired=0
	have_single=0
	if (( ${#R1S[@]} > 0 && ${#R2S[@]} > 0 )); then
		have_paired=1
		cat "${R1S[@]}" > "$cat_R1"
		cat "${R2S[@]}" > "$cat_R2"
	fi
	if (( ${#SES[@]} > 0 )); then
		have_single=1
		cat "${SES[@]}" > "$cat_SE"
	fi

	if (( have_paired == 0 && have_single == 0 )); then
		echo "$(timestamp): MetaPhlAn2: ERROR no cleaned reads found for ${sample}"
		exit 1
	fi

	# Build MetaPhlAn2 input
	mp_input="$cat_SE"
	if (( have_paired == 1 )); then
		mp_input="${cat_R1},${cat_R2}"
	fi

	# Compose MetaPhlAn2 command with explicit bowtie2 path and optional DB/PKL
	mp_cmd=( python "$metaphlan_py"
			"$mp_input"
			--input_type fastq
			--nproc "$num_cores"
			--bowtie2_exe "$bowtie2"
			-o "$prof_tsv" )

	# Optionally append DB/PKL if defined in the environment
	if [[ -n "${mpa_db:-}" ]]; then
		mp_cmd+=( --bowtie2db "$mpa_db" )
	fi
	if [[ -n "${mpa_pkl:-}" ]]; then
		mp_cmd+=( --mpa_pkl "$mpa_pkl" )
	fi

	# Run MetaPhlAn2
	"${mp_cmd[@]}"

	if [[ $? -ne 0 || ! -s "$prof_tsv" ]]; then
		echo "$(timestamp): MetaPhlAn2: ERROR profiling ${sample}"
		rm -rf "$tmp_dir"
		exit 1
	fi

	touch "$prof_done"
	rm -rf "$tmp_dir"
	echo "$(timestamp): MetaPhlAn2: profile created -> ${prof_tsv}"
fi

# cleanup reads workspace; keep only non-gz artifacts (e.g., *_DONE.txt)
find "$fastq_clean_dir" -type f -name '*.gz' -delete
find "$fastq_clean_dir" -type d -empty -delete
