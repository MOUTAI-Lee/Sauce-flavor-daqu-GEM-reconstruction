#!/usr/bin/env python3
"""Sum gene TPM by CAZy family using dbCAN3 consensus supported by >=2 methods."""
import csv,sys
from pathlib import Path
work=Path(sys.argv[1])
ann=work/'functional_annotation'/'dbcan'
tpm_dir=work/'functional_annotation'/'gene_tpm'
out=work/'functional_annotation'/'profiles'; out.mkdir(parents=True,exist_ok=True)
gene_families={}
for overview in ann.glob('*/overview.txt'):
    mag=overview.parent.name
    with overview.open(errors='ignore') as f:
        lines=[x.rstrip('\n').split('\t') for x in f if x.strip()]
    if len(lines)<2: continue
    header=[x.strip().lower() for x in lines[0]]
    # dbCAN3 overview commonly contains Gene ID, HMMER, DIAMOND, and dbCAN_sub.
    gene_idx=next((i for i,x in enumerate(header) if 'gene' in x or x in ('id','query')),0)
    method_idx=[i for i,x in enumerate(header) if any(k in x for k in ('hmmer','diamond','dbcan_sub','hotpep'))]
    for row in lines[1:]:
        if len(row)<=gene_idx: continue
        gene=row[gene_idx].strip()
        hits=[]
        for i in method_idx:
            if i<len(row) and row[i].strip() not in ('','-','NA'):
                hits.extend(v.strip() for v in row[i].replace(';',',').split(',') if v.strip() not in ('','-'))
        # Keep family labels supported by at least two distinct dbCAN methods.
        counts={}
        for h in hits: counts[h]=counts.get(h,0)+1
        for family,n in counts.items():
            if n>=2: gene_families.setdefault(gene,set()).add(family)
rows=[]
for fp in tpm_dir.glob('*_gene_TPM.tsv'):
    sample=fp.name.replace('_gene_TPM.tsv','')
    with fp.open(newline='') as f:
        reader=csv.DictReader(f,delimiter='\t')
        fields=reader.fieldnames or []
        gene_col=next((x for x in fields if x.lower() in ('contig','gene','name','sequence')),fields[0] if fields else None)
        tpm_col=next((x for x in fields if 'tpm' in x.lower()),None)
        if not gene_col or not tpm_col: continue
        sums={}
        for r in reader:
            gene=Path(r[gene_col]).name
            try: val=float(r[tpm_col])
            except: continue
            for fam in gene_families.get(gene,set()):
                sums[fam]=sums.get(fam,0.0)+val
        for fam,val in sums.items(): rows.append([sample,fam,val])
with (out/'sample_CAZy_category_TPM.tsv').open('w') as f:
    w=csv.writer(f,delimiter='\t'); w.writerow(['SampleID','CAZy_family','TPM_sum']); w.writerows(rows)
print(f"Consensus CAZy genes: {len(gene_families)}; sample-family records: {len(rows)}")
