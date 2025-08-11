#!/bin/bash
###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		assemble_libraries.sh 
###############################################################################

# create final.contigs.fa with megahit assembly from fastq/fasta files
assemble_libraries() {
    local sample="$1"
    local fastq_clean_dir="$2"
    local assembly_dir="$3"
    local assembly_extra_dir="$4"
    local num_cores="$5"

    # identify all libraries
    mkdir -p "$assembly_dir"
    echo "$(timestamp): ${fastq_clean_dir} contents:"
    ls "$fastq_clean_dir"/*
    python3 megahit_assembly/identify_fastq_files.py "$fastq_clean_dir" > "$assembly_dir/id_paths.txt"
    single_end_data="$(head -n 1 "$assembly_dir/id_paths.txt" | cut -f 1)"
    paired_end_data_1="$(head -n 1 "$assembly_dir/id_paths.txt" | cut -f 2)"
    paired_end_data_2="$(head -n 1 "$assembly_dir/id_paths.txt" | cut -f 3)"

    # assemble + PyDamage in the extra dir
    echo "$(timestamp): assemble_libraries: $sample"
    echo "__________________________________________________"
    megahit_assembler "$assembly_extra_dir" "$single_end_data" "$paired_end_data_1" "$paired_end_data_2" "$num_cores"
    echo "__________________________________________________"

    # Check for filtered output produced by megahit_assembler
    filtered_extra="${assembly_extra_dir}/$(basename "$assembly_extra_dir")_all_contigs.fa"
    if [ -e "$filtered_extra" ]; then
        echo "$(timestamp): assemble_libraries: filtered contigs file created"
        if ! [ -s "$filtered_extra" ]; then
            echo "$(timestamp): assemble_libraries: ERROR! filtered contigs file is empty"
            exit 1
        fi
    else
        echo "$(timestamp): assemble_libraries: ERROR! filtered contigs file not found at $filtered_extra"
        exit 1
    fi

    # Export exactly what we want to keep into the main assembly dir
    # 1) filtered contigs (final)
    mv "$filtered_extra" \
       "${assembly_dir}/${origin}_${sample}_all_contigs.fa"

    # 2) unfiltered backup
    cp -f "${assembly_extra_dir}/$(basename "$assembly_extra_dir")_all_contigs.fa.unfiltered.fa" \
          "${assembly_dir}/${origin}_${sample}_all_contigs.fa.unfiltered.fa"

    # 3) MEGAHIT log (file named 'log' in MEGAHIT output)
    if [ -e "${assembly_extra_dir}/log" ]; then
        mv "${assembly_extra_dir}/log" \
           "${assembly_dir}/${origin}_${sample}_log.txt"
    fi

    # 4) PyDamage results (move them over so we can delete extra dir)
    if [ -d "${assembly_extra_dir}/pydamage" ]; then
        mkdir -p "${assembly_dir}/pydamage"
        rsync -a "${assembly_extra_dir}/pydamage/" "${assembly_dir}/pydamage/"
    fi

    # cleanup helper files
    rm -f "$assembly_dir/id_paths.txt"

    # we are done with the extra dir; remove it entirely
    rm -rf "$assembly_extra_dir"
}