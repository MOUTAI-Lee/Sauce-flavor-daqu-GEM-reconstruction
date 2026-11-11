#!/usr/bin/env bash
# Edit these paths for your computing environment.
WORKDIR="${WORKDIR:-/path/to/MAGs_analysis}"
METADATA="${METADATA:-${WORKDIR}/metadata.tsv}"
CONDA_SH="${CONDA_SH:-$HOME/anaconda3/etc/profile.d/conda.sh}"

FASTP="${FASTP:-fastp}"
MEGAHIT="${MEGAHIT:-megahit}"
BOWTIE2="${BOWTIE2:-bowtie2}"
BOWTIE2_BUILD="${BOWTIE2_BUILD:-bowtie2-build}"
SAMTOOLS="${SAMTOOLS:-samtools}"
METAWrap_ENV="${METAWrap_ENV:-metawrap}"
CHECKM2_ENV="${CHECKM2_ENV:-checkm2}"
DREP_ENV="${DREP_ENV:-drep}"
GTDBTK_ENV="${GTDBTK_ENV:-gtdbtk}"
COVERM_ENV="${COVERM_ENV:-coverm}"
ANNOT_ENV="${ANNOT_ENV:-annotation}"

THREADS="${THREADS:-32}"
RAM_GB="${RAM_GB:-64}"
SEASONS=(Au Wi Sp Su)
declare -A GROUP_SAMPLES=(
  [Au]="Au1 Au2 Au3 Au4 Au5 Au6"
  [Wi]="Wi1 Wi2 Wi3 Wi4 Wi5 Wi6"
  [Sp]="Sp1 Sp2 Sp3 Sp4 Sp5 Sp6"
  [Su]="Su1 Su2 Su3 Su4 Su5 Su6"
)
