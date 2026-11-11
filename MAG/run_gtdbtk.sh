#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
source "$CONDA_SH"; conda activate "$GTDBTK_ENV"
GENOMES="${WORKDIR}/drep_out/dereplicated_genomes"
OUT="${WORKDIR}/gtdbtk_R214"
mkdir -p "$OUT"
gtdbtk classify_wf --genome_dir "$GENOMES" --out_dir "$OUT" --extension fa --cpus "$THREADS" \
  --skip_ani_screen >"${WORKDIR}/logs/gtdbtk.log" 2>&1
echo "GTDB-Tk classification completed. Confirm database is release R214."
