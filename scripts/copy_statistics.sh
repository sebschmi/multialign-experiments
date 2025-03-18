#!/bin/bash

rsync -arvmx --exclude '*.marker' --exclude '.snakemake_timestamp' --delete turso01:/wrk-vakka/users/sebschmi/multialign/data/statistics statistics
