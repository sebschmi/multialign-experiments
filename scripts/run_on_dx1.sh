#!/bin/bash

set +e

echo "Checking for running snakemake"
ps ux | grep -F "bin/snakemake " | grep -v grep
if [ "${PIPESTATUS[2]}" -ne "0" ]; then
    echo "No snakemake found"
else
    echo "Snakemake is already running!"
    exit 1
fi

set -e

nohup snakemake --cores 60 --config datadir=/abga/work/sebschmi/multialign --profile config/dx1 -p "$@" > log 2>&1 &
