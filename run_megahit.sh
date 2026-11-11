#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
OUT="${WORKDIR}/coassembly"; CLEAN="${WORKDIR}/clean_reads"
mkdir -p "$OUT" "${WORKDIR}/logs"
for G in "${SEASONS[@]}"; do
  R1=(); R2=()
  for S in ${GROUP_SAMPLES[$G]}; do
    [[ -s "${CLEAN}/${S}_R1.clean.fq.gz" && -s "${CLEAN}/${S}_R2.clean.fq.gz" ]] || { echo "Missing clean reads: $S" >&2; exit 1; }
    R1+=("${CLEAN}/${S}_R1.clean.fq.gz"); R2+=("${CLEAN}/${S}_R2.clean.fq.gz")
  done
  echo "Co-assembling ${G}: ${GROUP_SAMPLES[$G]}"
  "$MEGAHIT" -1 "$(IFS=,; echo "${R1[*]}")" -2 "$(IFS=,; echo "${R2[*]}")" \
    -o "${OUT}/${G}" -t "$THREADS" -m 0.9 --min-contig-len 1500 \
    >"${WORKDIR}/logs/megahit_${G}.log" 2>&1
done
echo "Seasonal co-assembly completed (minimum contig length: 1,500 bp)."
