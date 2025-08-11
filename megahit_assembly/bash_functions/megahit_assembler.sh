#!/bin/bash
###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		assembly_functions.sh 
###############################################################################

# contains the megahit command to assemble fastq/fasta files,
# then maps reads back to contigs and runs PyDamage to filter poor contigs.
megahit_assembler() {
    # args
    local output_dir="$1"
    local single_end_data="$2"      # "no_data" or comma-separated FASTQs
    local paired_end_data_1="$3"    # "no_data" or comma-separated R1 FASTQs
    local paired_end_data_2="$4"    # "no_data" or comma-separated R2 FASTQs
    local num_cores="$5"
    local sample_id
    sample_id="$(basename "$output_dir")"

    # PyDamage filtering threshold (default)
    local pydmg_thresh=0.5

    echo "$(timestamp): megahit_assembler: SE=$single_end_data"
    echo "$(timestamp): megahit_assembler: PE1=$paired_end_data_1"
    echo "$(timestamp): megahit_assembler: PE2=$paired_end_data_2"

    # 1) Assemble with MEGAHIT
    if ! [ "$single_end_data" == "no_data" ] && \
       ! [ "$paired_end_data_1" == "no_data" ] && \
       ! [ "$paired_end_data_2" == "no_data" ]; then
        echo "$(timestamp): assembling with BOTH paired-end and single-end data"
        "$megahit" -1 "$paired_end_data_1" -2 "$paired_end_data_2" -r "$single_end_data" \
                   -t "$num_cores" -o "$output_dir"
    elif ! [ "$single_end_data" == "no_data" ] && \
          [ "$paired_end_data_1" == "no_data" ] && \
          [ "$paired_end_data_2" == "no_data" ]; then
        echo "$(timestamp): assembling with SINGLE-END data"
        "$megahit" -r "$single_end_data" -t "$num_cores" -o "$output_dir"
    elif [ "$single_end_data" == "no_data" ] && \
         ! [ "$paired_end_data_1" == "no_data" ] && \
         ! [ "$paired_end_data_2" == "no_data" ]; then
        echo "$(timestamp): assembling with PAIRED-END data"
        "$megahit" -1 "$paired_end_data_1" -2 "$paired_end_data_2" -t "$num_cores" -o "$output_dir"
    else
        echo "$(timestamp): ERROR: libraries provided are not suitable for assembly"
        exit 1
    fi

    # MEGAHIT contigs
    local contigs_raw="${output_dir}/final.contigs.fa"
    if ! [ -s "$contigs_raw" ]; then
        echo "$(timestamp): ERROR: contigs not found at $contigs_raw"
        exit 1
    fi

    # 2) Align reads → contigs (Bowtie2) + MD tags
    local mapdir="${output_dir}/align"
    mkdir -p "$mapdir"
    local bt2_build
    bt2_build="$(dirname "$bowtie2")/bowtie2-build"
    local idx="${mapdir}/contigs"
    local sorted_bam="${mapdir}/${sample_id}.sorted.bam"
    local calmd_bam="${mapdir}/${sample_id}.calmd.bam"

    echo "$(timestamp): building Bowtie2 index"
    "$bt2_build" --threads "$num_cores" "$contigs_raw" "$idx"

    echo "$(timestamp): aligning reads to contigs (SE/PE aware)"
    if ! [ "$paired_end_data_1" == "no_data" ] && ! [ "$paired_end_data_2" == "no_data" ] && ! [ "$single_end_data" == "no_data" ]; then
        "$bowtie2" -x "$idx" -1 "$paired_end_data_1" -2 "$paired_end_data_2" -U "$single_end_data" \
                   --very-sensitive -k 1 --no-unal -p "$num_cores" \
        | "$samtools" view -@ "$num_cores" -b - \
        | "$samtools" sort -@ "$num_cores" -o "$sorted_bam" -
    elif ! [ "$paired_end_data_1" == "no_data" ] && ! [ "$paired_end_data_2" == "no_data" ]; then
        "$bowtie2" -x "$idx" -1 "$paired_end_data_1" -2 "$paired_end_data_2" \
                   --very-sensitive -k 1 --no-unal -p "$num_cores" \
        | "$samtools" view -@ "$num_cores" -b - \
        | "$samtools" sort -@ "$num_cores" -o "$sorted_bam" -
    else
        "$bowtie2" -x "$idx" -U "$single_end_data" \
                   --very-sensitive -k 1 --no-unal -p "$num_cores" \
        | "$samtools" view -@ "$num_cores" -b - \
        | "$samtools" sort -@ "$num_cores" -o "$sorted_bam" -
    fi
    "$samtools" index "$sorted_bam"

    echo "$(timestamp): adding MD tags (required by PyDamage)"
    "$samtools" calmd -@ "$num_cores" -b "$sorted_bam" "$contigs_raw" > "$calmd_bam"
    "$samtools" index "$calmd_bam"

    # 3) PyDamage (+ optional pruning + filtering)
    local bam_in="$calmd_bam"
    if command -v bamAlignCleaner >/dev/null 2>&1; then
        echo "$(timestamp): pruning empty contigs with bamAlignCleaner (optional)"
        local cleaned_bam="${mapdir}/${sample_id}.cleaned.bam"
        bamAlignCleaner -i "$calmd_bam" -o "$cleaned_bam"
        "$samtools" index "$cleaned_bam"
        bam_in="$cleaned_bam"
    fi

    local pd_dir="${output_dir}/pydamage"
    mkdir -p "$pd_dir"

    echo "$(timestamp): running PyDamage analyze"
    pydamage --outdir "$pd_dir" analyze --force -p "$num_cores" "$bam_in"

    echo "$(timestamp): filtering PyDamage results (threshold=$pydmg_thresh)"
    if [ -s "${pd_dir}/pydamage_results.csv" ]; then
        pydamage filter "${pd_dir}/pydamage_results.csv" -t "$pydmg_thresh"
    else
        echo "$(timestamp): WARNING: no PyDamage results CSV found"
    fi

    # 4) Create final *_all_contigs.fa filtered by PyDamage (keep unfiltered copy)
    local final_all="${output_dir}/$(basename "$output_dir")_all_contigs.fa"
    local final_all_unfiltered="${final_all}.unfiltered.fa"
    cp -f "$contigs_raw" "$final_all_unfiltered"

    # prefer the official filtered CSV name; fall back to unfiltered CSV
    local pd_filtered_csv="${pd_dir}/pydamage_filtered_results.csv"
    if [ ! -s "$pd_filtered_csv" ]; then
        pd_filtered_csv="${pd_dir}/pydamage_results.csv"
    fi

    # if still nothing, skip filtering and keep all contigs
    if [ ! -s "$pd_filtered_csv" ]; then
        echo "$(timestamp): PyDamage CSV not found; exporting UNFILTERED contigs."
        cp -f "$final_all_unfiltered" "$final_all"
        local n_total
        n_total=$(grep -c '^>' "$final_all_unfiltered" || true)
        echo "$(timestamp): PyDamage filter kept ${n_total}/${n_total} contigs"
        echo "$(timestamp): megahit_assembler completed with alignment (no PyDamage filter applied)"
        return 0
    fi

    # Extract contig IDs to keep from CSV (header-robust: 'reference' or 'contig')
    local keep_ids="${pd_dir}/keep_ids.txt"
    awk -F',' '
        NR==1 {
            for (i=1;i<=NF;i++) { h[tolower($i)]=i }
            refIdx = (h["reference"]?h["reference"]:(h["contig"]?h["contig"]:0))
            if (refIdx==0) { print "ERROR: missing reference/contig column" > "/dev/stderr"; exit 2 }
            next
        }
        { gsub(/"/,""); print $refIdx }
    ' "$pd_filtered_csv" > "$keep_ids"

    echo "$(timestamp): writing filtered contigs to $final_all"
    awk -v ids="$keep_ids" '
        BEGIN { while ((getline < ids) > 0) keep[$0]=1 }
        /^>/ {
            hdr=$0
            sub(/^>/,"",hdr)
            split(hdr,a,/[^[:alnum:]_.:-]+/)
            id=a[1]
            print_flag = (id in keep)
        }
        { if (print_flag) print }
    ' "$contigs_raw" > "$final_all"

    if ! grep -q "^>" "$final_all"; then
        echo "$(timestamp): WARNING: filtered FASTA is empty; restoring unfiltered."
        cp -f "$final_all_unfiltered" "$final_all"
    fi

    local n_total n_keep
    n_total=$(grep -c '^>' "$final_all_unfiltered" || true)
    n_keep=$(grep -c '^>' "$final_all" || true)
    echo "$(timestamp): PyDamage filter kept ${n_keep}/${n_total} contigs"
    echo "$(timestamp): megahit_assembler completed with alignment + PyDamage filtering"
}