#!/usr/bin/env bash

###############################################################################
#           Aydin Loid Karatas
#           ---
#           University of Southern California
#           Department of Quantitative and Computational Biology
#           Mooney Lab
#           ---
#           slurm.sh
###############################################################################


# validate before any worker creates output or starts software.
validate_cpus() {
    local requested=${1:-}
    local allocated=${SLURM_CPUS_PER_TASK:-${SLURM_CPUS_ON_NODE:-$requested}}
    if [[ ! $requested =~ ^[1-9][0-9]*$ ]] || \
        [[ ! $allocated =~ ^[1-9][0-9]*$ ]] || \
        (( requested > allocated )); then
        echo "invalid CPU request: $requested; allocation: $allocated" >&2
        return 2
    fi
    export OMP_NUM_THREADS="$requested" OPENBLAS_NUM_THREADS="$requested"
    export MKL_NUM_THREADS="$requested" NUMEXPR_NUM_THREADS="$requested"
}

# select physical manifest records, including a final unterminated record.
select_record() {
    local manifest=$1
    local index=${SLURM_ARRAY_TASK_ID:-}
    if [[ ! $index =~ ^[1-9][0-9]*$ ]] || [[ ! -r $manifest ]]; then
        echo "invalid array index '$index' or unreadable manifest: $manifest" >&2
        return 2
    fi
    local record
    record=$(awk -v record_number="$index" \
        'NR == record_number {print; exit}' "$manifest") || return
    if [[ ! $record =~ [^[:space:]] ]]; then
        echo "empty or out-of-range record $index in $manifest" >&2
        return 2
    fi
    printf '%s\n' "$record"
}

manifest_count() {
    local manifest=$1
    if [[ ! -r $manifest ]]; then
        echo "unreadable manifest: $manifest" >&2
        return 2
    fi
    awk '
        !NF { invalid = 1 }
        END {
            if (!NR || invalid) {
                print "empty manifest or blank record" > "/dev/stderr"
                exit 2
            }
            print NR
        }
    ' "$manifest"
}

# callers supply the established log directory and worker argument order.
submit_slurm() {
    local job_name=$1 log_dir=$2 count=$3 cpus=$4 memory=$5 mail_type=$6
    shift 6
    [[ $count =~ ^[1-9][0-9]*$ ]] || return 2
    [[ $cpus =~ ^[1-9][0-9]*$ ]] || return 2
    [[ $memory =~ ^[1-9][0-9]*$ ]] || return 2
    mkdir -p "$log_dir" || return
    sbatch --nodes=1 --ntasks=1 --cpus-per-task="$cpus" \
        --mem-per-cpu="${memory}G" --time=24:00:00 \
        --account="${VIROME_SLURM_ACCOUNT:-pi_bwknowle}" \
        --partition="${VIROME_SLURM_PARTITION:-pi_shared}" \
        --qos="${VIROME_SLURM_QOS:-pi_shared24}" \
        --array="1-${count}%4" --job-name="$job_name" \
        --chdir="${VIROME_CODE_DIR:-$HOME/project_coprolite_viromes}" \
        --output="${log_dir%/}/${job_name}.%A_%a.log" \
        --error="${log_dir%/}/${job_name}.%A_%a.log" \
        --mail-user="$USER@mail" --mail-type="$mail_type" \
        --export=ALL "$@"
}
