# MAG reconstruction, profiling and functional annotation

This pipeline is aligned with Methods 2.5.1–2.5.3.

## Workflow
1. `run_fastp.sh`: fastp v0.23.2; paired-end Q20 filtering and minimum read length 50 bp.
2. `run_megahit.sh`: seasonal co-assembly; contigs >=1,500 bp.
3. `run_stats_and_mapping.sh`: Bowtie2/Samtools mapping and assembly statistics.
4. `run_binning.sh`: MetaBAT2, MaxBin2 and CONCOCT through metaWRAP.
5. `run_refinement.sh`: metaWRAP bin refinement.
6. `run_checkm2.sh` + `classify_mag_quality.py`: CheckM2 plus rRNA/tRNA screening; HQ/MQ classification.
7. `run_drep.sh`: dRep ANI 95%, minimum aligned genome fraction 30%.
8. `run_gtdbtk.sh`: GTDB-Tk taxonomy; use GTDB release R214 database.
9. `run_coverm.sh`: CoverM v0.7.0, minimap2-sr, identity >=95%, aligned read percentage >=75%.
10. `summarize_mag_catalog.py <WORKDIR>`: create a MAG summary table including quality, assembly statistics, taxonomy and available ANI/AF.\n11. `run_functional_annotation.sh`: Prodigal single-genome mode, eggNOG-mapper and dbCAN3.

## MIMAG classification implemented
- HQ: completeness >=90%, contamination <=5%, 5S/16S/23S rRNA detected, and >=18 tRNAs.
- MQ: completeness >=50%, contamination <=10%, but not meeting all HQ criteria.
- MAGs meeting neither category are excluded.

## Input metadata
`metadata.tsv` columns must be:
`SampleID OriginalID Group Season R1 R2` (tab-separated).
Update raw read paths and `WORKDIR` in `config.sh` or export `WORKDIR` before running.

## Important software/database requirements
Use the versions stated in the manuscript: fastp 0.23.2; MEGAHIT 1.2.9; MetaBAT2 2.15; MaxBin2 2.2.7; CONCOCT 1.1.0; metaWRAP 1.3.2; CheckM2 1.0.2; dRep 3.4.5; GTDB-Tk 2.3.2 with GTDB R214; CoverM 0.7.0; Prodigal 2.6.3; eggNOG-mapper 2.1.12 with eggNOG 5.0.2; dbCAN3.
The scripts call installed executables; pin and record these versions in the actual conda environments before reproducing the published analysis.

12. `run_gene_tpm.sh`: gene-level TPM quantification for CAZyme profiling.\n13. `summarize_cazy_tpm.py <WORKDIR>`: join gene TPM with dbCAN3 consensus annotations (>=2 methods) and sum by CAZy family.\n14. `summarize_functional_profiles.py <WORKDIR>`: genome-size-normalized COG/KO/EC counts and abundance-weighted sample profiles.\n\n## Important implementation notes
- `run_checkm2.sh` expects `barrnap` and `tRNAscan-SE` available in `ANNOT_ENV`.
- Set `DBCAN_DB` to the local dbCAN3 database directory.
- CheckM2 report column names may differ by installation; `classify_mag_quality.py` expects `Name`, `Completeness`, and `Contamination`.
- The GTDB-Tk database must be release R214. The `--skip_ani_screen` option is used to avoid an additional screening step; remove it if not supported by your GTDB-Tk installation.
- `run_coverm.sh` profiles every sample against the complete dereplicated MAG catalog, not only its season-specific MAGs.
- The assembly-statistics script uses a built-in FASTA parser.\n- `summarize_functional_profiles.py` expects eggNOG-mapper annotation files named `<MAG>.emapper.annotations` and CoverM tables with a genome identifier plus a relative-abundance column; inspect headers and adjust aliases if your installed versions differ.\n- `run_gene_tpm.sh` produces gene-level TPM; dbCAN3 consensus calls (>=2 methods) must be joined to gene TPM to generate the final CAZy-category TPM table. The raw TPM table is retained for traceability.
