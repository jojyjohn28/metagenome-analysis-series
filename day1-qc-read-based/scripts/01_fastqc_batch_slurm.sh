#!/bin/bash
#SBATCH --job-name=fastqc_batch
#SBATCH --output=logs/slurm/fastqc_%j.out
#SBATCH --error=logs/slurm/fastqc_%j.err
#SBATCH --time=02:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --partition=compute

# Script: 01_fastqc_batch_slurm.sh
# Description: Run FastQC on multiple samples in batch (SLURM version)
# Author: github.com/jojyjohn28
# Usage: sbatch 01_fastqc_batch_slurm.sh

# Load modules (adjust for your HPC)
module load fastqc/0.11.9

# Set variables
INPUT_DIR="raw_data"
OUTPUT_DIR="qc/fastqc_raw"
THREADS=${SLURM_CPUS_PER_TASK}

# Create output directory
mkdir -p ${OUTPUT_DIR}
mkdir -p logs/slurm

echo "Starting FastQC analysis..."
echo "Job ID: ${SLURM_JOB_ID}"
echo "Running on node: ${SLURM_NODELIST}"
echo "CPUs: ${SLURM_CPUS_PER_TASK}"

# Run FastQC on all samples
fastqc -o ${OUTPUT_DIR} \
       -t ${THREADS} \
       ${INPUT_DIR}/*.fastq.gz

echo "FastQC batch processing complete!"
echo "Output directory: ${OUTPUT_DIR}"
