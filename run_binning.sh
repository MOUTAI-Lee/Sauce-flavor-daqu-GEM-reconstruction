#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
source "$CONDA_SH"; conda activate "$METAWrap_ENV"
CLEAN="${WORKDIR}/clean_reads"; COASM="${WORKDIR}/coassembly"; BIN="${WORKDIR}/binning"
LINKS="${WORKDIR}/reads_for_metawrap"
mkdir -p "$BIN" "$LINKS" "${WORKDIR}/logs"
for G in "${SEASONS[@]}"; do
  ARGS=()
  for S in ${GROUP_SAMPLES[$G]}; do
    R1="${LINKS}/${S}_1.fastq.gz"; R2="${LINKS}/${S}_2.fastq.gz"
    ln -sfn "${CLEAN}/${S}_R1.clean.fq.gz" "$R1"
    ln -sfn "${CLEAN}/${S}_R2.clean.fq.gz" "$R2"
    ARGS+=("$R1" "$R2")
  done
  metawrap binning -o "${BIN}/${G}" -t "$THREADS" -m "$RAM_GB" \
    -a "${COASM}/${G}/final.contigs.fa" --metabat2 --maxbin2 --concoct \
    "${ARGS[@]}" >"${WORKDIR}/logs/binning_${G}.log" 2>&1
done
echo "MetaWRAP binning completed."
