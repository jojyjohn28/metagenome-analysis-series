#!/bin/bash
#SBATCH --job-name=bbduk_host
#SBATCH --output=logs/slurm/bbduk_host_%j.out
#SBATCH --error=logs/slurm/bbduk_host_%j.err
#SBATCH --time=06:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=48G
#SBATCH --partition=compute

# Script: 04_bbduk_host_removal_slurm.sh
# Description: Remove host contamination using BBDuk (SLURM version)
# Author: github.com/jojyjohn28
# Usage: sbatch 04_bbduk_host_removal_slurm.sh

# Load modules
module load bbtools/38.90

# Set variables
INPUT_DIR="trimmed"
OUTPUT_DIR="decontaminated"
HOST_REF="databases/human_ref.fna"
THREADS=${SLURM_CPUS_PER_TASK}

# Create output directory
mkdir -p ${OUTPUT_DIR}
mkdir -p logs/slurm

echo "Starting BBDuk host removal..."
echo "Job ID: ${SLURM_JOB_ID}"
echo "Running on node: ${SLURM_NODELIST}"
echo "CPUs: ${SLURM_CPUS_PER_TASK}"

# Process each sample
for R1 in ${INPUT_DIR}/*_R1_paired.fastq.gz; do
    sample=$(basename ${R1} _R1_paired.fastq.gz)
    R2="${INPUT_DIR}/${sample}_R2_paired.fastq.gz"
    
    echo "Removing host from ${sample}..."
    
    bbduk.sh \
        in1=${R1} \
        in2=${R2} \
        out1=${OUTPUT_DIR}/${sample}_R1_clean.fastq.gz \
        out2=${OUTPUT_DIR}/${sample}_R2_clean.fastq.gz \
        outm1=${OUTPUT_DIR}/${sample}_R1_host.fastq.gz \
        outm2=${OUTPUT_DIR}/${sample}_R2_host.fastq.gz \
        ref=${HOST_REF} \
        k=31 \
        hdist=1 \
        threads=${THREADS} \
        stats=${OUTPUT_DIR}/${sample}_stats.txt
    
    echo "Completed ${sample}"
done

echo "BBDuk host removal complete!"
echo "Statistics saved in: ${OUTPUT_DIR}/*_stats.txt"
