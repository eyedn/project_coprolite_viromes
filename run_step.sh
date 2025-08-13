#!/bin/bash
###############################################################################
#     Aydin Karatas
#     Project Coprolite Viromes
#     run_step.sh 
###############################################################################
cd "$HOME/project_coprolite_viromes" || exit 1

script=$1
filename=$(basename "$script")

if [[ $filename =~ ^[0-9]+_ ]]; then
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
            run_group pal pal-AWC pal-BEL pal-BMS pal-ENG pal-ZAF pal-ZAP
            run_group ind ind-DNK ind-ESP ind-USA
            run_group pre pre-FJI pre-MDG pre-MEX pre-PER pre-TZA
            ;;
        *)
            echo "Invalid choice."
            exit 1
            ;;
    esac

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
            run_group pal pal-AWC pal-BEL pal-BMS pal-ENG pal-ZAF pal-ZAP
            ;;
        2)
            run_group ind ind-DNK ind-ESP ind-USA
            ;;
        3)
            run_group pre pre-FJI pre-MDG pre-MEX pre-PER pre-TZA
            ;;
        4)
            run_group pal pal-AWC pal-BEL pal-BMS pal-ENG pal-ZAF pal-ZAP
            run_group ind ind-DNK ind-ESP ind-USA
            run_group pre pre-FJI pre-MDG pre-MEX pre-PER pre-TZA
            ;;
        *)
            echo "Invalid choice."
            exit 1
            ;;
    esac
fi
