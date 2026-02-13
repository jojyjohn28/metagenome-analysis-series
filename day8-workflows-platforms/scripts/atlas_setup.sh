#!/bin/bash
# ATLAS: Scalable metagenomics with Snakemake
# Good for large datasets

# Install ATLAS
conda create -n atlas -c bioconda -c conda-forge metagenome-atlas
conda activate atlas

# Initialize project
atlas init --db-dir ~/atlas_databases my_atlas_project

# Download databases
atlas download --db-dir ~/atlas_databases

echo "Edit my_atlas_project/samples.tsv with your samples"
echo "Edit my_atlas_project/config.yaml for settings"
echo "Run: atlas run all --working-dir my_atlas_project --cores 32"
