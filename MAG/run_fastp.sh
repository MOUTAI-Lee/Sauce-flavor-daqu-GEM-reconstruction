#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
mkdir -p "${WORKDIR}"/{clean_reads,qc,logs}
[[ -f "$METADATA" ]] || { echo "ERROR: metadata not found: $METADATA" >&2; exit 1; }
command -v "$FASTP" >/dev/null || { echo "ERROR: fastp not found" >&2; exit 1; }

# Expected columns: SampleID OriginalID Group Season R1 R2
python - "$METADATA" <<'PY'
import csv,sys
with open(sys.argv[1],newline='') as f:
    r=csv.DictReader(f,delimiter='\t')
    required={'SampleID','OriginalID','Group','Season','R1','R2'}
    if not required.issubset(r.fieldnames or []):
        raise SystemExit(f"metadata must contain columns: {sorted(required)}")
    rows=list(r)
    if len(rows)!=24: print(f"WARNING: metadata contains {len(rows)} samples, not 24",file=sys.stderr)
    for x in rows:
        if not x['SampleID'] or not x['R1'] or not x['R2']:
            raise SystemExit(f"Incomplete metadata row: {x}")
PY

LOG="${WORKDIR}/logs/fastp_$(date +%Y%m%d_%H%M%S).log"
while IFS=$'\t' read -r SAMPLE ORIGINAL GROUP SEASON R1 R2; do
  [[ "$SAMPLE" == "SampleID" ]] && continue
  [[ -s "$R1" && -s "$R2" ]] || { echo "Missing input reads for $SAMPLE" | tee -a "$LOG"; exit 1; }
  echo "[$(date)] fastp: $SAMPLE" | tee -a "$LOG"
  "$FASTP" -i "$R1" -I "$R2" \
    -o "${WORKDIR}/clean_reads/${SAMPLE}_R1.clean.fq.gz" \
    -O "${WORKDIR}/clean_reads/${SAMPLE}_R2.clean.fq.gz" \
    -h "${WORKDIR}/qc/${SAMPLE}.fastp.html" \
    -j "${WORKDIR}/qc/${SAMPLE}.fastp.json" \
    --thread 8 --qualified_quality_phred 20 --length_required 50 \
    --unqualified_percent_limit 40 --n_base_limit 5 \
    --cut_front --cut_tail --cut_window_size 4 --cut_mean_quality 20 \
    >>"$LOG" 2>&1
done < "$METADATA"
echo "fastp completed: $LOG"
