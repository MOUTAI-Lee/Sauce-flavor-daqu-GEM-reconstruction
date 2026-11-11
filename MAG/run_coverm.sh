#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
source "$CONDA_SH"; conda activate "$COVERM_ENV"
GENOMES="${WORKDIR}/drep_out/dereplicated_genomes"
OUT="${WORKDIR}/coverm_abundance"
mkdir -p "$OUT"
shopt -s nullglob
GFILES=("$GENOMES"/*.fa)
((${#GFILES[@]})) || { echo "No dereplicated genomes in $GENOMES" >&2; exit 1; }
while IFS=$'\t' read -r SAMPLE ORIGINAL GROUP SEASON R1 R2; do
  [[ "$SAMPLE" == "SampleID" ]] && continue
  coverm genome --genome-fasta-files "${GFILES[@]}" --coupled "$R1" "$R2" \
    --mapper minimap2-sr --min-read-percent-identity 95 --min-read-aligned-percent 75 \
    --methods relative_abundance --threads "$THREADS" \
    --output-file "${OUT}/${SAMPLE}_relative_abundance.tsv" \
    >"${OUT}/${SAMPLE}.log" 2>&1
done < "$METADATA"
echo "CoverM relative abundance profiling completed."
