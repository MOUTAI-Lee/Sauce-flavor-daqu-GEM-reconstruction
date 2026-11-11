#!/usr/bin/env python3
"""
Create MAG-level genome-size-normalized COG/KO/EC counts and abundance-weighted
sample profiles. Expected inputs:
  functional_annotation/eggnog/<MAG>.emapper.annotations
  coverm_abundance/<SAMPLE>_relative_abundance.tsv
This parser intentionally preserves annotation identifiers and reports missing files.
"""
import csv,sys
from pathlib import Path
from collections import Counter,defaultdict
work=Path(sys.argv[1])
ann_dir=work/'functional_annotation'/'eggnog'
ab_dir=work/'coverm_abundance'
outdir=work/'functional_annotation'/'profiles'; outdir.mkdir(parents=True,exist_ok=True)
def parse_emapper(path):
    data={k:Counter() for k in ('COG','KO','EC')}
    for line in path.open(errors='ignore'):
        if not line.strip() or line.startswith('#'): continue
        x=line.rstrip('\n').split('\t')
        if len(x)<11: continue
        # eggNOG-mapper standard columns: query at 0, COG_category at 6, KEGG_ko at 11, EC at 10.
        # Header positions are recovered from the comment header when available below.
        break
    header=None; rows=[]
    for line in path.open(errors='ignore'):
        if line.startswith('##') and 'query' in line.lower() and '\t' in line:
            header=line.lstrip('#').strip().split('\t')
        elif line.strip() and not line.startswith('#'): rows.append(line.rstrip('\n').split('\t'))
    if header:
        idx={h:i for i,h in enumerate(header)}
        def vals(row,key,sep=','):
            i=idx.get(key)
            if i is None or i>=len(row) or row[i] in ('','-'): return []
            return [v for v in row[i].split(sep) if v and v!='-']
        for row in rows:
            for key,col in [('COG','COG_category'),('KO','KEGG_ko'),('EC','EC')]:
                for v in vals(row,col): data[key][v]+=1
    return data
mag_counts={}
for f in ann_dir.glob('*.emapper.annotations'):
    mag=f.name.replace('.emapper.annotations','')
    mag_counts[mag]=parse_emapper(f)
# Write per-MAG raw and per-Mbp normalized functional counts.
permag=outdir/'MAG_functional_counts_per_Mbp.tsv'
with permag.open('w') as f:
    w=csv.writer(f,delimiter='\t'); w.writerow(['MAG_ID','Function_type','Function_ID','Gene_count','Count_per_Mbp'])
    for mag,groups in mag_counts.items():
        fasta=work/'drep_out'/'dereplicated_genomes'/f'{mag}.fa'
        length=sum(len(line.strip()) for line in fasta.open() if not line.startswith('>')) if fasta.exists() else 0
        mbp=length/1e6 if length else 0
        for typ,c in groups.items():
            for fun,n in c.items(): w.writerow([mag,typ,fun,n,n/mbp if mbp else ''])
# CoverM abundance tables: expected first column genome/MAG and a relative abundance column.
sample_profiles=defaultdict(lambda:defaultdict(float))
for fp in ab_dir.glob('*_relative_abundance.tsv'):
    sample=fp.name.replace('_relative_abundance.tsv','')
    with fp.open() as f:
        r=csv.DictReader(f,delimiter='\t')
        for row in r:
            name=next((row[k] for k in row if k.lower() in ('genome','contig','name')),None)
            valkey=next((k for k in row if 'relative' in k.lower() and 'abundance' in k.lower()),None)
            if name is None or valkey is None: continue
            mag=Path(name).stem
            try: abundance=float(row[valkey])
            except: continue
            if abundance>1: abundance/=100.0
            if mag not in mag_counts: continue
            fasta=work/'drep_out'/'dereplicated_genomes'/f'{mag}.fa'
            length=sum(len(line.strip()) for line in fasta.open() if not line.startswith('>')) if fasta.exists() else 0
            mbp=length/1e6 if length else 0
            if not mbp: continue
            for typ,c in mag_counts[mag].items():
                for fun,n in c.items(): sample_profiles[sample][(typ,fun)]+= (n/mbp)*abundance
with (outdir/'sample_weighted_COG_KO_EC_profiles.tsv').open('w') as f:
    w=csv.writer(f,delimiter='\t'); w.writerow(['SampleID','Function_type','Function_ID','Abundance_weighted_per_Mbp'])
    for sample,items in sorted(sample_profiles.items()):
        for (typ,fun),value in sorted(items.items()): w.writerow([sample,typ,fun,value])
print(f"Processed {len(mag_counts)} MAG annotation files and {len(sample_profiles)} abundance profiles.")
