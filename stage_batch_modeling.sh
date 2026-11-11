#!/usr/bin/env bash
# Canonical GEM reconstruction: CarveMe with M9 gap filling.
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
source "$CONDA_SH"; conda activate "$CONDA_ENV"
cd "$GEM_WORKDIR"
OUT="${GEM_WORKDIR}/04_models_final"
LOGDIR="${GEM_WORKDIR}/logs"
mkdir -p "$OUT" "$LOGDIR"
shopt -s nullglob
FAAS=("$PROTEIN_DIR"/*.faa)
((${#FAAS[@]})) || { echo "No .faa files in $PROTEIN_DIR" >&2; exit 1; }
SUCCESS=0; FAIL=0
for FAA in "${FAAS[@]}"; do
  ID=$(basename "$FAA" .faa); XML="${OUT}/${ID}.xml"; LOG="${OUT}/${ID}.log"
  echo "[$((SUCCESS+FAIL+1))/${#FAAS[@]}] ${ID}"
  if [[ -s "$XML" ]]; then SUCCESS=$((SUCCESS+1)); continue; fi
  if carve "$FAA" -g "$MEDIA" --fbc2 --solver "$SOLVER" -o "$XML" >"$LOG" 2>&1 && [[ -s "$XML" ]]; then
    SUCCESS=$((SUCCESS+1))
  else
    FAIL=$((FAIL+1)); rm -f "$XML"; echo "FAILED: $ID; see $LOG" >&2
  fi
done
printf "Total=%s\tSuccess=%s\tFailed=%s\n" "${#FAAS[@]}" "$SUCCESS" "$FAIL" | tee "${OUT}/modeling_summary.tsv"
(( FAIL == 0 )) || exit 2
