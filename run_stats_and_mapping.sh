#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
CLEAN="${WORKDIR}/clean_reads"; COASM="${WORKDIR}/coassembly"
MAP="${WORKDIR}/mapping"; STATS="${WORKDIR}/assembly_stats"
mkdir -p "$MAP" "$STATS" "${WORKDIR}/logs"
for G in "${SEASONS[@]}"; do
  FA="${COASM}/${G}/final.contigs.fa"
  [[ -s "$FA" ]] || { echo "Missing assembly: $FA" >&2; exit 1; }
  IDX="${MAP}/${G}_index"
  "$BOWTIE2_BUILD" --threads "$THREADS" "$FA" "$IDX" >"${WORKDIR}/logs/index_${G}.log" 2>&1
  # Basic assembly statistics: total length, contig count, N50, GC%.
  python - "$FA" "${STATS}/${G}_assembly_stats.tsv" <<'PY'
import sys
seqs=[]; name=None; chunks=[]
for line in open(sys.argv[1]):
    line=line.strip()
    if line.startswith(">"):
        if name is not None: seqs.append("".join(chunks))
        name=line[1:]; chunks=[]
    else: chunks.append(line)
if name is not None: seqs.append("".join(chunks))
if not seqs: raise SystemExit("No contigs")
lens=sorted((len(x) for x in seqs),reverse=True)
total=sum(lens); cumulative=0; n50=0
for n in lens:
    cumulative+=n
    if cumulative>=total/2: n50=n; break
gc=sum(x.upper().count("G")+x.upper().count("C") for x in seqs)
bases=sum(map(len,seqs))
with open(sys.argv[2],"w") as f:
    f.write("contigs\ttotal_length_bp\tN50_bp\tGC_percent\tmin_contig_bp\n")
    f.write(f"{len(seqs)}\t{total}\t{n50}\t{gc/bases*100:.3f}\t{min(lens)}\n")
PY
  for S in ${GROUP_SAMPLES[$G]}; do
    "$BOWTIE2" -x "$IDX" -1 "${CLEAN}/${S}_R1.clean.fq.gz" -2 "${CLEAN}/${S}_R2.clean.fq.gz" \
      -p "$THREADS" --no-unal 2>"${MAP}/${S}.bowtie2.log" |
      "$SAMTOOLS" view -@ "$THREADS" -b - |
      "$SAMTOOLS" sort -@ "$THREADS" -o "${MAP}/${S}.bam"
    "$SAMTOOLS" index "${MAP}/${S}.bam"
  done
done
echo "Mapping and assembly statistics completed."
