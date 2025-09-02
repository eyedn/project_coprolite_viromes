#!/bin/bash
###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		pydamage.sh 
###############################################################################
#$ -cwd
#$ -N pydam
#$ -o $SCRATCH/joblogs/pydamage_extra/
#$ -j y
#$ -pe shared 8
#$ -l h_rt=25:00:00,h_data=8G
#$ -M $USER@mail 
#$ -m ea 
#$ -cwd

set -euo pipefail

timestamp(){ date '+%Y-%m-%d %H:%M:%S'; }

usage() {
    cat <<'EOF'
Usage:
    qsub pydamage_on_contigs.qsub.sh -- \
    -c <contigs.fa> \
    -o <output_dir> \
    [-1 <R1.fastq[.gz]>] [-2 <R2.fastq[.gz]>] [-U <SE.fastq[.gz]>] \
    [-t <threads>] [-T <pydmg_thresh>] [-s <sample_id>]

Notes:
  * Provide reads as any combo of -1/-2/-U (SE and/or PE). At least one of them is required.
  * Output files:
        <output_dir>/<sample_id>_all_contigs.fa.unfiltered
        <output_dir>/<sample_id>_all_contigs.fa            (PyDamage-filtered; falls back to unfiltered)
  * Requires bowtie2, samtools, pydamage on PATH (e.g., your "qc" conda env).
EOF
}

# -------------------- (optional) environment setup ----------------------------
# If you need modules/conda, uncomment/edit these lines for your Hoffman setup.
# source /u/local/Modules/default/init/modules.sh
# module load anaconda3
# conda activate qc

# ----------------------------- CLI args --------------------------------------
contigs=""
outdir=""
R1="no_data"
R2="no_data"
SE="no_data"
threads="${NSLOTS:-16}"     # use grid slots; default 16
pydmg_thresh="0.5"
sample_id=""

# SGE passes args after a literal "--" separator; support both styles.
while getopts ":c:o:1:2:U:t:T:s:h" opt; do
    case "$opt" in
        c) contigs="$OPTARG" ;;
        o) outdir="$OPTARG" ;;
        1) R1="$OPTARG" ;;
        2) R2="$OPTARG" ;;
        U) SE="$OPTARG" ;;
        t) threads="$OPTARG" ;;
        T) pydmg_thresh="$OPTARG" ;;
        s) sample_id="$OPTARG" ;;
        h) usage; exit 0 ;;
        \?) echo "Unknown option: -$OPTARG" >&2; usage; exit 1 ;;
        :)  echo "Missing argument for -$OPTARG" >&2; usage; exit 1 ;;
    esac
done

# ----------------------------- Checks ----------------------------------------
if [[ -z "$contigs" || -z "$outdir" ]]; then
    echo "ERROR: -c <contigs.fa> and -o <outdir> are required." >&2
    usage; exit 1
fi
if [[ "$R1" == "no_data" && "$R2" == "no_data" && "$SE" == "no_data" ]]; then
    echo "ERROR: Provide at least one of -1, -2, or -U (reads required)." >&2
    usage; exit 1
fi
if [[ ! -s "$contigs" ]]; then
    echo "ERROR: contigs FASTA not found or empty: $contigs" >&2
    exit 1
fi

# Make sure the qsub stdout/stderr directory exists (SGE won't create it)
mkdir -p "$SCRATCH/joblogs/pydamage_extra/"

# ---------------------------- Paths & names ----------------------------------
mkdir -p "$outdir"
sample_id="${sample_id:-$(basename "$contigs" | sed 's/\.[Ff][Aa]\([Ss][Tt]\)\{0,1\}[Aa]*$//')}"
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
bt2_build="$(command -v bowtie2-build || true)"
bowtie2="$(command -v bowtie2 || true)"
samtools="$(command -v samtools || true)"
pydamage="$(command -v pydamage || true)"

if [[ -z "$bt2_build" || -z "$bowtie2" || -z "$samtools" || -z "$pydamage" ]]; then
    echo "ERROR: bowtie2-build, bowtie2, samtools, and pydamage must be on PATH." >&2
    exit 1
fi

# ------------------------------ Align (Step 2) --------------------------------
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

# ------------------------------ PyDamage (Step 3) -----------------------------
echo "$(timestamp): running PyDamage analyze (threads=$threads)"
rm -rf "$pd_dir"; mkdir -p "$pd_dir"
"$pydamage" --outdir "$pd_dir" analyze --force -p "$threads" "$calmd_bam"

echo "$(timestamp): filtering PyDamage results (threshold=$pydmg_thresh)"
if [[ -s "${pd_dir}/pydamage_results.csv" ]]; then
    "$pydamage" filter "${pd_dir}/pydamage_results.csv" -t "$pydmg_thresh" || true
else
    echo "$(timestamp): WARNING: no pydamage_results.csv; continuing without filter step"
fi

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
