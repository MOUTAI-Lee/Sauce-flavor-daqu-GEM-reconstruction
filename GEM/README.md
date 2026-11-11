# GEM reconstruction and SMETANA interaction analysis

Aligned with Methods 2.6.

## Canonical workflow
1. Prepare protein-coding sequences (`proteins/*.faa`) from the non-redundant MAGs using Prodigal single-genome mode (see MAGs pipeline).
2. `stage_batch_modeling.sh`: CarveMe v1.6.6 reconstruction with M9 gap filling; output SBML models in `models_final/`.
3. `run_memote_batch.sh`: MEMOTE v0.17.0 quality reports.
4. `stage_smetana.sh`: SMETANA v1.2.1 global and detailed analyses under the same M9 medium; summarize donor/receiver and metabolite-level exchanges.

## Model construction
The previous grampos/gramneg phylum-based Universe selection has been removed. The canonical workflow uses CarveMe gap filling with M9 (`carve proteins.faa -g M9`). This avoids assigning Gram status from phylum labels. All models intended for comparison are reconstructed using the same medium and solver settings.

## Outputs
- `models_final/*.xml`: gap-filled SBML models.
- `validation/memote_reports/*_memote.html`: MEMOTE reports.
- `smetana/global_results_global.tsv`: global MRO/MIP results (subject to installed SMETANA output naming).
- `smetana/detailed_results_detailed.tsv`: metabolite-specific donor/receiver exchanges.
- `smetana/metabolic_exchange_summary.tsv`: donor/receiver totals, pairwise exchange counts and metabolite categories.

## Requirements
CarveMe 1.6.6, MEMOTE 0.17.0, SMETANA 1.2.1, COBRApy and the configured solver. Confirm exact executable versions in the environment before execution.

## Important interpretation
Donor/receiver assignments and exchanges are model-predicted potential interactions under standardized M9 conditions. They are not measured in situ fluxes. The summary script recognizes common detailed-output column aliases; if your installed SMETANA version uses different headers, update the aliases in `summarize_smetana.py` after inspecting the raw TSV. Metabolite categorization is name-based and should be manually reviewed for publication.
