#!/bin/bash

set +e

echo "Checking for running snakemake"
ps ux | grep -F "multialign/bin/snakemake " | grep -v grep
if [ "${PIPESTATUS[2]}" -ne "0" ]; then
    echo "No snakemake found"
else
    echo "Snakemake is already running!"
    exit 1
fi

echo "Checking if there are any existing slurm jobs"
if [ -z "$(squeue -o '%A %.28R %j' -u $(whoami) -M all | grep 'multialign')" ]; then
    echo "No slurm jobs found"
else
    echo "Found slurm jobs"
    squeue -o '%A %.28R %j' -u $(whoami) -M all | grep 'multialign'
    exit 1
fi

set -e

if [ $# -eq 0 ]; then
    echo "Error: no snakemake target given"
    exit 1
fi

source $HOME/.bashrc
cd /home/sebschmi/git/multialign

source activate multialign

# Create log directory
LOGDIR="logs/$(date +"%FT%R:%S")/"
mkdir -p "$LOGDIR"
LOGDIR=$(realpath $LOGDIR)
LATEST_LOGDIR_SYMLINK="logs/latest"
rm -f "$LATEST_LOGDIR_SYMLINK"
ln -sr "$LOGDIR" "$LATEST_LOGDIR_SYMLINK"

echo "Storing logs in directory $LOGDIR"
echo "Also symlinked as $LATEST_LOGDIR_SYMLINK"
echo "$LOGDIR" > .logdir

# Clean shadow directory
# echo "Cleaning shadow directory"
# snakemake --profile config/turso --cleanup-shadow >> "$LOGDIR/run_on_turso.log" 2>&1

export TMPDIR="/wrk-vakka/users/sebschmi/multialign/tmp"
export TEMP=$TMPDIR
export TMP=$TMPDIR
mkdir -p "$TMPDIR"

# Execute pipeline
echo "Creating jobs"

echo "Arguments: $@" >> "$LOGDIR/run_on_turso.log"
echo "Start time: $(date +"%FT%R:%S")" >> "$LOGDIR/run_on_turso.log"
nohup snakemake --profile config/turso "$@" >> "$LOGDIR/run_on_turso.log" 2>&1 &

echo "Started snakemake in background with PID $!"
