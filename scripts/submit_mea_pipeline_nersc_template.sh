#!/bin/bash
#SBATCH --job-name=mea_ephys
#SBATCH --account=<YOUR_NERSC_ACCOUNT>
#SBATCH --qos=regular
#SBATCH --constraint=gpu
#SBATCH --gpus=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=128GB
#SBATCH --time=03:00:00
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err

set -euo pipefail

# Load user-editable paths and settings
# This allows the script to work even if sbatch is launched from another folder.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${REPO_DIR}/run_config.env"

# Load software
module load conda/Miniforge3-25.9.1-0
conda activate "$CONDA_ENV"
module load openjdk/17

# Make required folders
mkdir -p "$RESULTS_PATH" "$WORK_DIR" "$LOG_DIR" "$TMPDIR" "$KACHERY_DIR"
mkdir -p "$RESULTS_PATH/nextflow"

# Runtime environment
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
export KACHERY_DIR="$KACHERY_DIR"
export TMPDIR="$TMPDIR"
export PROJECT_DIR="$PROJECT_DIR"
export RESULTS_PATH="$RESULTS_PATH"

# Run pipeline
cd "$PIPELINE_DIR/pipeline"

nextflow -C nextflow_nersc_template.config \
  -log "$RESULTS_PATH/nextflow/nextflow.log" \
  run main_multi_backend.nf \
  --input nwb \
  --ecephys_path "$DATA_DIR" \
  --runmode spikesort \
  --n_jobs 1 \
  --preprocessing_args "--motion skip --denoising cmr" \
  --spikesorting_args "--skip-motion-correction" \
  --params_file "$PARAMS_FILE" \
  --results_path "$RESULTS_PATH" \
  -work-dir "$WORK_DIR" \
  -resume
