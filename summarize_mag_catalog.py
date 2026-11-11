#!/usr/bin/env python3
"""Combine CheckM2/MIMAG classification, genome statistics and GTDB-Tk taxonomy."""
import csv,sys
from pathlib import Path
work=Path(sys.argv[1])
def read_tsv(p):
    if not p.exists(): return [],[]
    with p.open(newline='') as f:
        r=csv.DictReader(f,delimiter='\t'); return r.fieldnames or [],list(r)
_,qrows=read_tsv(work/'checkm2_results'/'MAG_quality_classification.tsv')
gtdb_files=list((work/'gtdbtk_R214').glob('*summary.tsv'))
_,trows=read_tsv(gtdb_files[0]) if gtdb_files else ([],[])
tax={}
for r in trows:
    k=r.get('user_genome') or r.get('name') or r.get('user_genome_id')
    if k: tax[Path(k).stem]=r
genomes=work/'drep_out'/'dereplicated_genomes'; out=[]
for q in qrows:
    mid=q['MAG_ID']; f=genomes/(mid+'.fa')
    if not f.exists(): continue
    seqs=[]; chunks=[]
    for line in f.open():
        x=line.strip()
        if x.startswith('>'):
            if chunks: seqs.append(''.join(chunks)); chunks=[]
        else: chunks.append(x)
    if chunks: seqs.append(''.join(chunks))
    lens=sorted(map(len,seqs),reverse=True); total=sum(lens); cum=0; n50=0
    for n in lens:
        cum+=n
        if cum>=total/2: n50=n; break
    bases=sum(map(len,seqs)); gc=sum(x.upper().count('G')+x.upper().count('C') for x in seqs)
    tr=tax.get(mid,{})
    out.append({'MAG_ID':mid,'MIMAG_category':q.get('MIMAG_category',''),
      'Completeness':q.get('Completeness',''),'Contamination':q.get('Contamination',''),
      'Genome_size_bp':total,'Contig_number':len(seqs),'N50_bp':n50,
      'GC_percent':f'{gc/bases*100:.3f}' if bases else '',
      'rRNA_types_detected':q.get('rRNA_types_detected',''),'tRNA_count':q.get('tRNA_count',''),
      'GTDB_taxonomy':tr.get('classification',''),
      'Closest_reference_genome':tr.get('closest_genome_reference',''),
      'Closest_reference_ANI':tr.get('closest_genome_ani',''),
      'Closest_reference_AF':tr.get('closest_genome_af','')})
cols=list(out[0]) if out else ['MAG_ID']
with (work/'MAG_catalog_summary.tsv').open('w') as f:
    w=csv.DictWriter(f,fieldnames=cols,delimiter='\t'); w.writeheader(); w.writerows(out)
print(f"Wrote {len(out)} dereplicated MAG records.")
