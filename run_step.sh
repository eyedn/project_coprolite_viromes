#!/bin/bash
###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       run_step.sh
###############################################################################


set -euo pipefail

export VIROME_CODE_DIR="${VIROME_CODE_DIR:-$HOME/project_coprolite_viromes}"
cd "$VIROME_CODE_DIR" || exit 1

script=$1
filename=$(basename "$script")

if [ "$filename" = "4_analyze_checkv_genomes.sh" ]; then
    # complete CheckV genomes are processed once per trimming filter.
    ./run_ori.sh -s "$script" -d 8 -c "${CORES:-8}" \
        -p "$SCRATCH/project_coprolite_viromes" -o checkv-conservative
    ./run_ori.sh -s "$script" -d 8 -c "${CORES:-8}" \
        -p "$SCRATCH/project_coprolite_viromes" -o checkv-aggressive
elif [[ $filename =~ ^[0-9]+_ ]]; then
    # run main pipeline step
    echo "Which sample group(s) do you want to run?"
    echo "  1) pal"
    echo "  2) ind"
    echo "  3) pre"
    echo "  4) all (pal, ind, pre)"
    read -rp "Enter choice (1/2/3/4): " choice

    run_group() {
        local group=$1
        shift
        for origin in "$@"; do
            ./run_ori.sh -s "$script" -d 8 -c "${CORES:-8}" -p "$SCRATCH/project_coprolite_viromes" -o "$origin"
        done
    }

    case "$choice" in
        1)
            run_group pal pal-AUT pal-AWC pal-BEL pal-BMS pal-ENG pal-ZAF pal-ZAP
            ;;
        2)
            run_group ind ind-CHN ind-DNK ind-ESP ind-USA
            ;;
        3)
            run_group pre pre-FJI pre-MDG pre-MEX pre-NPL pre-PER pre-TZA
            ;;
        4)
            run_group pal pal-AUT pal-AWC pal-BEL pal-BMS pal-ENG pal-ZAF pal-ZAP
            run_group ind ind-CHN ind-DNK ind-ESP ind-USA
            run_group pre pre-FJI pre-MDG pre-MEX pre-NPL pre-PER pre-TZA
            ;;
        *)
            echo "Invalid choice."
            exit 1
            ;;
    esac

elif [ "$filename" = "3a_get_alignment_counts.sh" ]; then
    # stage 3a aggregates the full ORF pool: 16 GB per slot, 64 GB total.
    ./run_ori.sh -s "$script" -d 16 -c 4 \
        -p "$SCRATCH/project_coprolite_viromes" -o all
elif [ "$filename" = "4a_get_checkv_genome_stats.sh" ]; then
    # stage 4a runs serially: one CPU with 32 GB total memory.
    ./run_ori.sh -s "$script" -d 32 -c 1 \
        -p "$SCRATCH/project_coprolite_viromes" -o all
elif [[ $filename =~ ^[0-9]+a_ ]]; then
    # run auxiliary script not specific to origin
    ./run_ori.sh -s "$script" -d 8 -c 4 -p "$SCRATCH/project_coprolite_viromes" -o all
else
    # special case for running a specific script not in the pipeline directory
    echo "Which sample group(s) do you want to run?"
    echo "  1) pal"
    echo "  2) ind"
    echo "  3) pre"
    echo "  4) all (pal, ind, pre)"
    read -rp "Enter choice (1/2/3/4): " choice

    run_group() {
        local group=$1
        shift
        for origin in "$@"; do
            ./run_ori.sh -s "$script" -d 8 -c "${CORES:-8}" -p "$SCRATCH/project_coprolite_viromes" -o "$origin"
        done
    }

    case "$choice" in
        1)
            run_group pal pal-AUT pal-AWC pal-BEL pal-BMS pal-ENG pal-ZAF pal-ZAP
            ;;
        2)
            run_group ind ind-CHN ind-DNK ind-ESP ind-USA
            ;;
        3)
            run_group pre pre-FJI pre-MDG pre-MEX pre-NPL pre-PER pre-TZA
            ;;
        4)
            run_group pal pal-AUT pal-AWC pal-BEL pal-BMS pal-ENG pal-ZAF pal-ZAP
            run_group ind ind-CHN ind-DNK ind-ESP ind-USA
            run_group pre pre-FJI pre-MDG pre-MEX pre-NPL pre-PER pre-TZA
            ;;
        *)
            echo "Invalid choice."
            exit 1
            ;;
    esac
fi
