#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
source "$CONDA_SH"; conda activate "$DREP_ENV"
IN="${WORKDIR}/checkm2_results/qualified_MAGs/all"
OUT="${WORKDIR}/drep_out"
mkdir -p "$OUT"
shopt -s nullglob
GENOMES=("$IN"/*.fa)
((${#GENOMES[@]})) || { echo "No HQ/MQ MAGs found in $IN" >&2; exit 1; }
# dRep -sa: ANI threshold; -nc: minimum aligned coverage/overlap fraction.
dRep dereplicate "$OUT" -g "${GENOMES[@]}" -comp 50 -con 10 -sa 0.95 -nc 0.30 -p "$THREADS" \
  >"${WORKDIR}/logs/drep.log" 2>&1
echo "dRep completed: ANI 95%, minimum genome overlap 30%."
