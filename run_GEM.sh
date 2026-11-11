#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
source "$CONDA_SH"; conda activate "$CONDA_ENV"
mkdir -p "${GEM_WORKDIR}/logs"
echo "CarveMe version: $(carve --version 2>&1 | head -1 || true)"
echo "Use the project-selected representative MAG protein file to test CarveMe with M9 gap filling."
if [[ -x "${SCRIPT_DIR}/test_carveme_single.sh" ]]; then
  bash "${SCRIPT_DIR}/test_carveme_single.sh"
else
  echo "Provide test_carveme_single.sh or proceed with stage2_batch_modeling.sh."
fi
