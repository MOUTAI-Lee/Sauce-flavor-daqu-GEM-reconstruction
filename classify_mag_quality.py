#!/usr/bin/env python3
"""Classify MAGs using CheckM2 plus rRNA/tRNA evidence (MIMAG criteria)."""
import csv, re, shutil, sys
from pathlib import Path
report, genome_dir, outdir = map(Path, sys.argv[1:4])
outdir.mkdir(parents=True, exist_ok=True)
with report.open() as f:
    reader=csv.DictReader(f, delimiter='\t')
    rows=list(reader)
def findval(row, candidates):
    for k in candidates:
        if k in row and row[k] not in ('',None): return float(row[k])
    raise KeyError(f"Cannot find any of {candidates} in CheckM2 columns {list(row)}")
def rrna_count(gff):
    types=set()
    if gff.exists():
        for line in gff.read_text(errors='ignore').splitlines():
            if line.startswith('#') or not line.strip(): continue
            cols=line.split('\t')
            if len(cols)>2:
                typ=cols[2].lower()
                if 'rrna' in typ or 'ribosomal' in typ:
                    attr=cols[8].lower() if len(cols)>8 else ''
                    types.add('5S' if '5s' in attr or '5s' in typ else
                              '16S' if '16s' in attr or '16s' in typ else
                              '23S' if '23s' in attr or '23s' in typ else 'OTHER')
    return types
def trna_count(txt):
    if not txt.exists(): return 0
    n=0
    for line in txt.read_text(errors='ignore').splitlines():
        s=line.strip()
        if not s or s.startswith(('Name','------','Sequence','tRNA')):
            continue
        # Standard tRNAscan-SE tabular records begin with a sequence name and numeric coordinates.
        if re.match(r'^\S+\s+\d+\s+\d+\s+',s): n+=1
    return n
rows_out=[]
for row in rows:
    name=row.get('Name') or row.get('name') or row.get('Bin Id') or row.get('Genome')
    if not name: continue
    name=Path(name).name
    if name.endswith('.fa'): name=name[:-3]
    comp=findval(row,['Completeness','completeness'])
    cont=findval(row,['Contamination','contamination'])
    rr=rrna_count(outdir/'rrna'/f'{name}.gff')
    tr=trna_count(outdir/'trna'/f'{name}.txt')
    hq=(comp>=90 and cont<=5 and {'5S','16S','23S'}.issubset(rr) and tr>=18)
    mq=(comp>=50 and cont<=10 and not hq)
    status='HQ' if hq else ('MQ' if mq else 'Excluded')
    src=genome_dir/f'{name}.fa'
    if not src.exists():
        # CheckM2 may retain suffixes in Name; try exact filename.
        candidates=list(genome_dir.glob(name+'*.fa'))
        if candidates: src=candidates[0]
    if status in ('HQ','MQ') and src.exists():
        dest=outdir/'qualified_MAGs'/status
        dest.mkdir(parents=True,exist_ok=True)
        shutil.copy2(src,dest/src.name)
    rows_out.append([name,comp,cont,rr,tr,status])
with (outdir/'MAG_quality_classification.tsv').open('w') as f:
    w=csv.writer(f,delimiter='\t'); w.writerow(['MAG_ID','Completeness','Contamination','rRNA_types_detected','tRNA_count','MIMAG_category']); w.writerows(rows_out)
# Combined qualified directory for downstream dRep.
combined=outdir/'qualified_MAGs'/'all'
combined.mkdir(parents=True,exist_ok=True)
for cat in ('HQ','MQ'):
    for src in (outdir/'qualified_MAGs'/cat).glob('*.fa'):
        shutil.copy2(src,combined/src.name)
print(f"Classified {len(rows_out)} MAGs; HQ={sum(x[-1]=='HQ' for x in rows_out)}, MQ={sum(x[-1]=='MQ' for x in rows_out)}")
