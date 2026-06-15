# Running the MEA Ephys Nextflow Pipeline on NERSC

This guide explains how to run the MEA electrophysiology Nextflow pipeline on NERSC using reusable template files.

Users only need to edit:

1. Copy `run_config.example.env` to `run_config.env`, then edit `run_config.env`
2. The NERSC account line in `scripts/submit_mea_pipeline_nersc_template.sh`

## What the pipeline does

The pipeline runs:

1. job dispatch
2. preprocessing
3. Kilosort4 spike sorting
4. postprocessing
5. curation
6. visualization
7. report generation
8. burst detection
9. results collection
10. NWB export

Nextflow uses `-resume`, so completed steps can be reused instead of rerunning everything.


## How the code is organized

Most users only need to clone this main repository:

    BenShalomLab/MEA-ephys-pipeline

The workflow also uses a few separate capsule repositories. Users do not need to clone these manually. The pipeline downloads the pinned versions automatically during the run.

Separate capsule repositories used by the workflow:

    Varda006/aind-ephys-preprocessing
    Varda006/aind-ephys-curation
    Varda006/aind-ecephys-nwb

These are kept separate so each pipeline block can be versioned and updated independently. The exact tested versions are pinned in:

    pipeline/capsule_versions.env

### What was modified in the separate capsule repos

#### aind-ephys-preprocessing

This repo contains the preprocessing capsule used before spike sorting.

In this NERSC setup, it is used as the validated preprocessing block for preparing MEA/NWB recordings before Kilosort4. Keeping it as a separate repo allows preprocessing fixes to be made and pinned without copying the whole capsule into the main workflow repository.

#### aind-ephys-curation

This repo contains the curation capsule used after postprocessing.

The pipeline computes many quality metrics during postprocessing and curation. The current default filtering rule uses a small subset of those metrics:

    isi_violations_ratio < 0.5 and presence_ratio > 0.8 and firing_rate > 0.1

This rule keeps units that are active enough, consistently present, and have lower contamination. Users can later modify the curation rule to include additional metrics depending on their experiment.

#### aind-ecephys-nwb

This repo contains the NWB export capsule.

It is used to write processed electrophysiology outputs and curated units into NWB-compatible output. Keeping this capsule separate makes it easier to update NWB export behavior while keeping the main workflow stable.

### Local capsules kept in this main repo

Two custom capsules are kept directly inside this main repository because they are part of the NERSC-validated workflow:

    capsules/report_generation
    capsules/burst_detection

These two folders were compared against the successful NERSC run work directories and match the code used during validation.


## Files users edit

### 1. `run_config.env`

Start by copying the example file:

    cp run_config.example.env run_config.env

Then edit `run_config.env`. This file controls paths for the run.

Main value to update:

    export PROJECT_DIR=/path/to/your/project_folder

Example:

    export PROJECT_DIR=/pscratch/sd/<first-letter>/<username>/mea_pipeline_run

Other paths are built automatically:

    export PIPELINE_DIR=${PROJECT_DIR}/MEA-ephys-pipeline
    export DATA_DIR=${PROJECT_DIR}/data
    export RESULTS_PATH=${PROJECT_DIR}/results
    export WORK_DIR=${PROJECT_DIR}/nextflow_work
    export LOG_DIR=${PROJECT_DIR}/logs
    export TMPDIR=${PROJECT_DIR}/tmp
    export KACHERY_DIR=${PROJECT_DIR}/tmp/kachery
    export PARAMS_FILE=${PIPELINE_DIR}/scripts/params_no_motion.json
    export CONDA_ENV=env_ephys

### 2. `scripts/submit_mea_pipeline_nersc_template.sh`

Update this line:

    #SBATCH --account=<YOUR_NERSC_ACCOUNT>

Example:

    #SBATCH --account=m2043

## Folder setup

Create the required folders:

    mkdir -p $PROJECT_DIR/data
    mkdir -p $PROJECT_DIR/results
    mkdir -p $PROJECT_DIR/nextflow_work
    mkdir -p $PROJECT_DIR/logs
    mkdir -p $PROJECT_DIR/tmp/kachery
    mkdir -p $PROJECT_DIR/scripts

Put the input NWB or MEA files in:

    $DATA_DIR

## Parameter file

The default parameter file is:

    scripts/params_no_motion.json

The pipeline computes many quality metrics during postprocessing and curation. The current default curation rule uses a small subset of those metrics:

    isi_violations_ratio < 0.5 and presence_ratio > 0.8 and firing_rate > 0.1

This means the pipeline keeps units that are active enough, consistently present, and have lower contamination. Users can later modify the curation rule to include additional metrics depending on their experiment.

## Submit the run

From the repository folder:

    sbatch scripts/submit_mea_pipeline_nersc_template.sh

## Check job status

    squeue -u $USER

`PD` means the job is pending.  
`R` means the job is running.

If the job disappears from the queue, it either completed or failed. Check the Nextflow log.

## Check pipeline progress

    grep "Cached process\|Submitted process\|ERROR\|failed\|Workflow completed" $RESULTS_PATH/nextflow/nextflow.log | tail -100

A successful run should show:

    Workflow completed
    failedCount=0

## Main outputs

Final outputs are saved in:

    $RESULTS_PATH

Important folders:

    results/nwb
    results/spikesorted
    results/curated
    results/postprocessed
    results/visualization
    results/nextflow

Important Nextflow summary files:

    results/nextflow/dag.html
    results/nextflow/report.html
    results/nextflow/timeline.html
    results/nextflow/trace.txt

## Report generation outputs

Report generation produces files such as:

    waveforms_grid.pdf
    locations_unfiltered.pdf
    locations_206_units.pdf
    metrics_curated.xlsx
    qm_unfiltered.xlsx
    rejection_log.xlsx
    report_summary.json
    spike_times.npy

## Burst detection outputs

Burst detection produces files such as:

    network_results.json
    raster_burst_plot.png
    raster_burst_plot.svg
    raster_burst_plot_30s.png
    raster_burst_plot_30s.svg
    raster_burst_plot_60s.svg
    burst_detection.log

## Reusable files

The reusable NERSC files are:

    run_config.example.env
    pipeline/nextflow_nersc_template.config
    scripts/submit_mea_pipeline_nersc_template.sh
    scripts/params_no_motion.json

The validated Varda-specific config is kept separately as:

    pipeline/nextflow_nersc_local.config

Do not rely on another user's `/pscratch` folder. Each user should set their own `PROJECT_DIR`.
