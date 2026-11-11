#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
source "$CONDA_SH"; conda activate "$METAWrap_ENV"
BIN="${WORKDIR}/binning"; REF="${WORKDIR}/refinement"; ALL="${WORKDIR}/all_refined_bins"
mkdir -p "$REF" "$ALL" "${WORKDIR}/logs"
for G in "${SEASONS[@]}"; do
  A=()
  [[ -d "${BIN}/${G}/metabat2_bins" ]] && A+=(-A "${BIN}/${G}/metabat2_bins")
  [[ -d "${BIN}/${G}/maxbin2_bins" ]] && A+=(-B "${BIN}/${G}/maxbin2_bins")
  [[ -d "${BIN}/${G}/concoct_bins" ]] && A+=(-C "${BIN}/${G}/concoct_bins")
  ((${#A[@]})) || { echo "No bins found for $G" >&2; exit 1; }
  metawrap bin_refinement -o "${REF}/${G}" -t "$THREADS" -m "$RAM_GB" -c 50 -x 10 "${A[@]}" \
    >"${WORKDIR}/logs/refinement_${G}.log" 2>&1
done
rm -f "$ALL"/*.fa
printf "MAG_ID\tOriginal_bin\tSeason\tSource\n" > "${ALL}/rename_mapping.tsv"
for G in "${SEASONS[@]}"; do
  SRC="${REF}/${G}/metawrap_50_10_bins"; i=0
  [[ -d "$SRC" ]] || continue
  while IFS= read -r F; do
    i=$((i+1)); ID=$(printf "%s_BIN%03d" "$G" "$i")
    cp "$F" "${ALL}/${ID}.fa"
    printf "%s\t%s\t%s\t%s\n" "$ID" "$(basename "$F")" "$G" "$SRC" >> "${ALL}/rename_mapping.tsv"
  done < <(find "$SRC" -maxdepth 1 -type f -name '*.fa' | sort)
done
echo "Refinement completed."
