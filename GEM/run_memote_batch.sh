#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
source "$CONDA_SH"; conda activate "$CONDA_ENV"
OUT="${GEM_WORKDIR}/04_models_final"; REPORTS="${GEM_WORKDIR}/05_validation/memote_reports"
mkdir -p "$REPORTS" "${GEM_WORKDIR}/logs"
LOG="${GEM_WORKDIR}/logs/memote_$(date +%Y%m%d_%H%M%S).log"
shopt -s nullglob; MODELS=("$OUT"/*.xml)
((${#MODELS[@]})) || { echo "No SBML models found" >&2; exit 1; }
FAIL=0
for MODEL in "${MODELS[@]}"; do
  ID=$(basename "$MODEL" .xml)
  if memote report snapshot --filename "${REPORTS}/${ID}_memote.html" "$MODEL" >>"$LOG" 2>&1; then
    echo "MEMOTE PASS: $ID"
  else
    echo "MEMOTE FAIL: $ID"; FAIL=$((FAIL+1))
  fi
done
echo "MEMOTE reports: $REPORTS; failures=$FAIL"
(( FAIL == 0 ))
