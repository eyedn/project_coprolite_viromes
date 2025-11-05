#!/bin/bash
###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       pydamage.sh
###############################################################################
#$ -cwd
#$ -N pydam
#$ -o /u/scratch/a/ayd1n/joblogs/pydamage_extra/
#$ -j y
#$ -pe shared 8
#$ -l h_rt=20:00:00,h_data=8G
#$ -M $USER@mail
#$ -m ea

for FILE in ~/project_coprolite_viromes/general_bash_functions/* ; do source $FILE ; done


set -euo pipefail

usage() {
    cat <<'EOF'
Usage (fixed order, no flags):

  qsub pydamage_on_contigs.qsub.sh \
      <contigs.fa> \
      <output_dir> \
      <R1.fastq[.gz] or -> \
      <R2.fastq[.gz] or -> \
      <SE.fastq[.gz] or -> \
      <threads or -> \
      <pydmg_thresh or -> \
      <sample_id or ->

Notes:
  * Provide reads as any combo, but at least one of R1/R2/SE must be non-"-".
    - Paired-end: R1 and R2 set; SE should be "-"
    - Single-end: SE set; R1 and R2 should be "-"
  * Use "-" to accept defaults for threads (NSLOTS/16), threshold (0.5), or sample_id (derived from contigs filename).
  * Output files:
      <output_dir>/<sample_id>_all_contigs.fa.unfiltered
      <output_dir>/<sample_id>_all_contigs.fa
  * Requires bowtie2, samtools, pydamage on PATH (e.g., your "qc" conda env).
EOF
}

# ---------------------------- environment setup -------------------------------
source /u/local/Modules/default/init/modules.sh
module load anaconda3
conda activate qc

# ----------------------------- Positional args --------------------------------
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || "$#" -lt 2 ]]; then
    usage; exit 0
fi

contigs="${1:-}"
outdir="${2:-}"
R1="${3:-"-"}"
R2="${4:-"-"}"
SE="${5:-"-"}"
threads_in="${6:-"-"}"
pydmg_thresh_in="${7:-"-"}"
sample_id_in="${8:-"-"}"

# ----------------------------- Defaults/normalize -----------------------------
if [[ -z "$contigs" ]]; then
    echo "ERROR: <contigs.fa> is required." >&2
    usage; exit 1
fi

# Interpret "-" as "no_data" for read args
R1="${R1:-"-"}"; [[ "$R1" == "-" ]] && R1="no_data"
R2="${R2:-"-"}"; [[ "$R2" == "-" ]] && R2="no_data"
SE="${SE:-"-"}"; [[ "$SE" == "-" ]] && SE="no_data"

# Threads default: prefer NSLOTS if available, else 16
threads="${threads_in}"
if [[ -z "${threads}" || "${threads}" == "-" ]]; then
    threads="${NSLOTS:-16}"
fi

# Threshold default 0.5
pydmg_thresh="${pydmg_thresh_in}"
if [[ -z "${pydmg_thresh}" || "${pydmg_thresh}" == "-" ]]; then
    pydmg_thresh="0.5"
fi

# Sample ID default derived from contigs filename (strip common fasta extensions)
if [[ -z "${sample_id_in}" || "${sample_id_in}" == "-" ]]; then
    sample_id="$(basename "$contigs" | sed 's/\.[Ff][Aa]\([Ss][Tt]\)\{0,1\}[Aa]*$//')"
else
    sample_id="${sample_id_in}"
fi

# ----------------------------- Checks ----------------------------------------
if [[ "$R1" == "no_data" && "$R2" == "no_data" && "$SE" == "no_data" ]]; then
    echo "ERROR: Provide at least one read input among R1, R2, or SE." >&2
    usage; exit 1
fi
if [[ ! -s "$contigs" ]]; then
    echo "ERROR: contigs FASTA not found or empty: $contigs" >&2
    exit 1
fi

# Ensure log dir exists for SGE
mkdir -p "$SCRATCH/joblogs/pydamage_extra/"

# ---------------------------- Paths & names ----------------------------------
mkdir -p "$outdir"
mapdir="${outdir}/align"
pd_dir="${outdir}/pydamage"
idx="${mapdir}/contigs"
sorted_bam="${mapdir}/${sample_id}.sorted.bam"
calmd_bam="${mapdir}/${sample_id}.calmd.bam"
final_all="${outdir}/${sample_id}_all_contigs.fa"
final_all_unfiltered="${final_all}.unfiltered"
pd_filtered_csv="${pd_dir}/pydamage_filtered_results.csv"
keep_ids="${pd_dir}/keep_ids.txt"

mkdir -p "$mapdir" "$pd_dir"

# --------------------------- Tool discovery ----------------------------------
bt2_build="$software/bowtie2-2.5.1-linux-x86_64/bowtie2-build"
bowtie2="$software/bowtie2-2.5.1-linux-x86_64/bowtie2"
samtools="$software/samtools-1.18/samtools"
pydamage="$(command -v pydamage || true)" 

if [[ ! -x "$bt2_build" || ! -x "$bowtie2" || ! -x "$samtools" || -z "$pydamage" ]]; then
    echo "ERROR: One or more required tools not found/executable:" >&2
    echo "  bt2_build: $bt2_build" >&2
    echo "  bowtie2:   $bowtie2" >&2
    echo "  samtools:  $samtools" >&2
    echo "  pydamage:  $pydamage" >&2
    exit 1
fi

# ------------------------------ Align (Step 2) --------------------------------
# Skip alignment + MD tagging entirely if final output already exists
if [[ -f "$calmd_bam" ]]; then
    echo "$(timestamp): $calmd_bam already exists — skipping alignment and calmd steps."
else
    echo "$(timestamp): building Bowtie2 index"
    "$bt2_build" --threads "$threads" "$contigs" "$idx"

    echo "$(timestamp): aligning reads to contigs (SE/PE aware)"
    if [[ "$R1" != "no_data" && "$R2" != "no_data" && "$SE" != "no_data" ]]; then
        "$bowtie2" -x "$idx" -1 "$R1" -2 "$R2" -U "$SE" --very-sensitive -k 1 --no-unal -p "$threads" \
        | "$samtools" view -@ "$threads" -b - \
        | "$samtools" sort -@ "$threads" -o "$sorted_bam" -
    elif [[ "$R1" != "no_data" && "$R2" != "no_data" ]]; then
        "$bowtie2" -x "$idx" -1 "$R1" -2 "$R2" --very-sensitive -k 1 --no-unal -p "$threads" \
        | "$samtools" view -@ "$threads" -b - \
        | "$samtools" sort -@ "$threads" -o "$sorted_bam" -
    elif [[ "$SE" != "no_data" ]]; then
        "$bowtie2" -x "$idx" -U "$SE" --very-sensitive -k 1 --no-unal -p "$threads" \
        | "$samtools" view -@ "$threads" -b - \
        | "$samtools" sort -@ "$threads" -o "$sorted_bam" -
    else
        echo "ERROR: invalid read combination." >&2
        exit 1
    fi
    "$samtools" index "$sorted_bam"

    echo "$(timestamp): adding MD tags (samtools calmd)"
    "$samtools" calmd -@ "$threads" -b "$sorted_bam" "$contigs" > "$calmd_bam"
    "$samtools" index "$calmd_bam"
fi

# ------------------------------ PyDamage (Step 3) -----------------------------
echo "$(timestamp): running PyDamage analyze (threads=$threads)"
rm -rf "$pd_dir"; mkdir -p "$pd_dir"
"$pydamage" --outdir "$pd_dir" analyze --force -p "$threads" "$calmd_bam"

echo "$(timestamp): filtering PyDamage results (threshold=$pydmg_thresh)"
"$pydamage" --outdir "$pd_dir" filter  "${pd_dir}/pydamage_results.csv"

# ----------------------- Export filtered FASTA (Step 4) -----------------------
echo "$(timestamp): writing unfiltered copy -> $final_all_unfiltered"
cp -f "$contigs" "$final_all_unfiltered"

csv_to_use=""
if [[ -s "$pd_filtered_csv" ]]; then
    csv_to_use="$pd_filtered_csv"
elif [[ -s "${pd_dir}/pydamage_results.csv" ]]; then
    csv_to_use="${pd_dir}/pydamage_results.csv"
fi

if [[ -z "$csv_to_use" ]]; then
    echo "$(timestamp): PyDamage CSV not found; exporting UNFILTERED contigs as final."
    cp -f "$final_all_unfiltered" "$final_all"
else
    # Extract contig IDs to keep (header-robust: 'reference' or 'contig')
    awk -F',' '
        NR==1 {
            for (i=1;i<=NF;i++) { h[tolower($i)]=i }
            refIdx = (h["reference"]?h["reference"]:(h["contig"]?h["contig"]:0))
            if (refIdx==0) { print "ERROR: missing reference/contig column" > "/dev/stderr"; exit 2 }
            next
        }
        { gsub(/"/,""); print $refIdx }
    ' "$csv_to_use" > "$keep_ids"

    echo "$(timestamp): exporting filtered contigs -> $final_all"
    awk -v ids="$keep_ids" '
    BEGIN { while ((getline < ids) > 0) keep[$0]=1 }
    /^>/ {
        hdr=$0; sub(/^>/,"",hdr)
        split(hdr,a,/[^[:alnum:]_.:-]+/)
        id=a[1]
        print_flag = (id in keep)
    }
    { if (print_flag) print }
    ' "$contigs" > "$final_all"

    if ! grep -q "^>" "$final_all"; then
        echo "$(timestamp): WARNING: filtered FASTA is empty; restoring unfiltered."
        cp -f "$final_all_unfiltered" "$final_all"
    fi
fi

n_total=$(grep -c '^>' "$final_all_unfiltered" || true)
n_keep=$(grep -c '^>' "$final_all" || true)
echo "$(timestamp): PyDamage filter kept ${n_keep}/${n_total} contigs"
echo "$(timestamp): done."
