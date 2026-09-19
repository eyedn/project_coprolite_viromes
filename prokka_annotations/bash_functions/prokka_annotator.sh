#!/usr/bin/env bash
###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       prokka_annotator.sh
###############################################################################
# Run Prokka and, only for CheckV genomes, optionally retain completed GFF/FAA
# output when Prokka's optional GenBank/Sequin export fails.
checkv_prokka_outputs_complete() {
    local annot_dir="$1"
    local sample="$2"
    local gff_path="${annot_dir}/${sample}.gff"
    local faa_path="${annot_dir}/${sample}.faa"

    if [ ! -s "$gff_path" ] || [ ! -s "$faa_path" ]; then
        return 1
    fi

    awk '
        /^##gff-version 3$/ { has_gff_version = 1; next }
        /^##FASTA$/ { has_fasta_marker = 1; next }
        has_fasta_marker && /^>/ { has_fasta_sequence = 1; next }
        !has_fasta_marker && $0 !~ /^#/ && NF == 9 { has_feature = 1 }
        END {
            exit !(has_gff_version && has_feature && has_fasta_marker \
                && has_fasta_sequence)
        }
    ' "$gff_path"
}

prokka_annotator() {
	local sample=$1
	local contigs_file=$2
	local custom_db=$3
	local annot_dir=$4
	local type=$5
	local label=$6
	local num_cores=$7
	local mode=${8:-strict}
	local prokka_status

	echo "$(timestamp): prokka_annotator: annotating genes for $type"
	echo "$(timestamp): prokka_annotator: contigs file: $contigs_file"
	echo "$(timestamp): prokka_annotator: custom database: $custom_db"

	if [ "$custom_db" != "no_data" ]; then
		if prokka \
			--proteins "$custom_db" \
			--outdir "$annot_dir" \
			--prefix "$sample" \
			--kingdom "$type" \
			--fast \
			--metagenome \
			--cpus "$num_cores" \
			"$contigs_file"
		then
			return 0
		else
			prokka_status=$?
		fi
	else
		if prokka \
			--outdir "$annot_dir" \
			--prefix "$sample" \
			--kingdom "$type" \
			--fast \
			--metagenome \
			--cpus "$num_cores" \
			"$contigs_file"
		then
			return 0
		else
			prokka_status=$?
		fi
	fi

	if [ "$mode" != "checkv_tolerant" ]; then
		return "$prokka_status"
	fi
	if ! checkv_prokka_outputs_complete "$annot_dir" "$sample"; then
		return "$prokka_status"
	fi

	echo "$(timestamp): WARNING: Prokka returned ${prokka_status}, but " \
		"required GFF/FAA outputs are complete; accepting optional " \
		".gbk/.sqn export failure for CheckV."
	return 0
}
