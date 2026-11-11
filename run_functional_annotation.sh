#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
source "$CONDA_SH"; conda activate "$ANNOT_ENV"
GENOMES="${WORKDIR}/drep_out/dereplicated_genomes"
OUT="${WORKDIR}/functional_annotation"
mkdir -p "$OUT"/{genes,proteins,eggnog,dbcan,logs}
for F in "$GENOMES"/*.fa; do
  ID=$(basename "$F" .fa)
  prodigal -i "$F" -a "${OUT}/proteins/${ID}.faa" -d "${OUT}/genes/${ID}.ffn" \
    -f gff -o "${OUT}/genes/${ID}.gff" -p single \
    >"${OUT}/logs/${ID}.prodigal.log" 2>&1
done
# eggNOG-mapper: COG, KO and EC annotations in one protein annotation run.
emapper.py --input_dir "${OUT}/proteins" --output_dir "${OUT}/eggnog" \
  --itype proteins -m diamond --cpu "$THREADS" --output MAGs \
  >"${OUT}/logs/eggnog.log" 2>&1
# dbCAN3: run the three evidence methods; downstream retain CAZymes supported by >=2 methods.
for FAA in "${OUT}"/proteins/*.faa; do
  ID=$(basename "$FAA" .faa)
  run_dbcan protein "$FAA" --out_dir "${OUT}/dbcan/${ID}" \
    --db_dir "${DBCAN_DB:-/path/to/dbcan_db}" --tools diamond,hmmer,dbCAN \
    --dia_cpu "$THREADS" --hmm_cpu "$THREADS" \
    >"${OUT}/logs/${ID}.dbcan.log" 2>&1
done
echo "Prodigal, eggNOG-mapper and dbCAN3 annotation completed."
