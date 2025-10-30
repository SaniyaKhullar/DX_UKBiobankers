#!/bin/bash

# Please run this code on DNA Nexus to test that PGSC_Calculator
# works for you :)

CMD="curl -fsSL get.nextflow.io | bash; \
    mkdir -p ~/.local/bin; \
    mv nextflow ~/.local/bin; \
    export PATH=\"\$PATH:~/.local/bin\"; \
    nextflow run pgscatalog/pgsc_calc -profile test,docker"

dx run swiss-army-knife \
    -icmd="$CMD" \
    --priority high \
    --tag="demo_pgscalc" \
    --instance-type mem3_ssd1_v2_x4