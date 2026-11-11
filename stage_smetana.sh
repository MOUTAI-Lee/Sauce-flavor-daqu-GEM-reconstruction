#!/usr/bin/env bash
# SMETANA v1.2.1, standardized M9-based medium.
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
source "$CONDA_SH"; conda activate "$CONDA_ENV"
MODELS="${GEM_WORKDIR}/04_models_final"; OUT="${GEM_WORKDIR}/06_smetana"
mkdir -p "$OUT" "${GEM_WORKDIR}/logs"
LOG="${GEM_WORKDIR}/logs/smetana_$(date +%Y%m%d_%H%M%S).log"
shopt -s nullglob; XML=("$MODELS"/*.xml)
((${#XML[@]})) || { echo "No SBML models in $MODELS" >&2; exit 1; }
smetana --global --flavor fbc2 --media "$MEDIA" --solver "$SOLVER" \
  -o "${OUT}/global_results" "${XML[@]}" >"$LOG" 2>&1
smetana --detailed --flavor fbc2 --media "$MEDIA" --solver "$SOLVER" \
  -o "${OUT}/detailed_results" "${XML[@]}" >>"$LOG" 2>&1
python "${SCRIPT_DIR}/summarize_smetana.py" "${OUT}/detailed_results_detailed.tsv" "${OUT}/metabolic_exchange_summary.tsv"
echo "SMETANA global and detailed analyses completed."
