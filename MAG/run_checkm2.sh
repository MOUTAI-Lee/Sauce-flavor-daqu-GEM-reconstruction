#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
source "$CONDA_SH"; conda activate "$CHECKM2_ENV"
ALL="${WORKDIR}/all_refined_bins"; OUT="${WORKDIR}/checkm2_results"
mkdir -p "$OUT" "${WORKDIR}/logs"
checkm2 predict --threads "$THREADS" --input "$ALL" --output-directory "$OUT" -x fa \
  >"${WORKDIR}/logs/checkm2.log" 2>&1
REPORT="${OUT}/quality_report.tsv"
[[ -s "$REPORT" ]] || { echo "CheckM2 report missing" >&2; exit 1; }
# Detect rRNA/tRNA features independently; these determine MIMAG HQ status.
source "$CONDA_SH"; conda activate "${ANNOT_ENV}"
mkdir -p "${OUT}/rrna" "${OUT}/trna"
for F in "$ALL"/*.fa; do
  ID=$(basename "$F" .fa)
  barrnap --kingdom bac "$F" > "${OUT}/rrna/${ID}.gff" 2>"${OUT}/rrna/${ID}.log" || true
  tRNAscan-SE -B -o "${OUT}/trna/${ID}.txt" "$F" >"${OUT}/trna/${ID}.log" 2>&1 || true
done
python "${SCRIPT_DIR}/classify_mag_quality.py" "$REPORT" "$ALL" "$OUT" 
echo "MIMAG-style HQ/MQ classification completed."
