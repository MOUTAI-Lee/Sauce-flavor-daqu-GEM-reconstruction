#!/usr/bin/env bash
# Quantify MAG-derived coding genes as TPM for CAZyme abundance profiling.
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
source "$CONDA_SH"; conda activate "$COVERM_ENV"
ANN="${WORKDIR}/functional_annotation"; GENES="${ANN}/genes"
OUT="${WORKDIR}/functional_annotation/gene_tpm"
mkdir -p "$OUT"
COMBINED="${OUT}/all_MAG_genes.ffn"
: > "$COMBINED"
for F in "$GENES"/*.ffn; do
  [[ -s "$F" ]] || continue
  cat "$F" >> "$COMBINED"
done
[[ -s "$COMBINED" ]] || { echo "No Prodigal gene nucleotide files found" >&2; exit 1; }
while IFS=$'\t' read -r SAMPLE ORIGINAL GROUP SEASON R1 R2; do
  [[ "$SAMPLE" == "SampleID" ]] && continue
  coverm contig --reference "$COMBINED" --coupled "$R1" "$R2" \
    --mapper minimap2-sr --min-read-percent-identity 95 --min-read-aligned-percent 75 \
    --methods tpm --threads "$THREADS" \
    --output-file "${OUT}/${SAMPLE}_gene_TPM.tsv" \
    >"${OUT}/${SAMPLE}.log" 2>&1
done < "$METADATA"
echo "Gene-level TPM tables generated. Map gene IDs to dbCAN3 consensus annotations for CAZy-category summaries."
