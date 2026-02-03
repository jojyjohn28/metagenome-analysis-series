#!/bin/bash
#SBATCH --job-name=trimmomatic
#SBATCH --output=logs/slurm/trimmomatic_%j.out
#SBATCH --error=logs/slurm/trimmomatic_%j.err
#SBATCH --time=04:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --partition=compute

# Script: 02_trimmomatic_batch_slurm.sh
# Description: Run Trimmomatic on multiple samples (SLURM version)
# Author: github.com/jojyjohn28
# Usage: sbatch 02_trimmomatic_batch_slurm.sh

# Load modules
module load trimmomatic/0.39
module load java/11

# Set variables
INPUT_DIR="raw_data"
OUTPUT_DIR="trimmed"
ADAPTER_FILE="adapters/TruSeq3-PE.fa"
THREADS=${SLURM_CPUS_PER_TASK}

# Create directories
mkdir -p ${OUTPUT_DIR}
mkdir -p logs/trimmomatic
mkdir -p logs/slurm

echo "Starting Trimmomatic analysis..."
echo "Job ID: ${SLURM_JOB_ID}"
echo "Running on node: ${SLURM_NODELIST}"
echo "CPUs: ${SLURM_CPUS_PER_TASK}"

# Process each sample
for R1 in ${INPUT_DIR}/*_R1.fastq.gz; do
    sample=$(basename ${R1} _R1.fastq.gz)
    R2="${INPUT_DIR}/${sample}_R2.fastq.gz"
    
    echo "Processing ${sample}..."
    
    trimmomatic PE \
        -threads ${THREADS} \
        -phred33 \
        ${R1} ${R2} \
        ${OUTPUT_DIR}/${sample}_R1_paired.fastq.gz \
        ${OUTPUT_DIR}/${sample}_R1_unpaired.fastq.gz \
        ${OUTPUT_DIR}/${sample}_R2_paired.fastq.gz \
        ${OUTPUT_DIR}/${sample}_R2_unpaired.fastq.gz \
        ILLUMINACLIP:${ADAPTER_FILE}:2:30:10:2:True \
        LEADING:3 \
        TRAILING:3 \
        SLIDINGWINDOW:4:15 \
        MINLEN:36 \
        2> logs/trimmomatic/${sample}.log
    
    echo "Completed ${sample}"
done

# Generate summary statistics
echo "Generating summary statistics..."
echo "Sample,Input_Pairs,Both_Surviving,Forward_Only,Reverse_Only,Dropped" > trimmomatic_summary.csv

for log in logs/trimmomatic/*.log; do
    sample=$(basename ${log} .log)
    input=$(grep "Input Read Pairs" ${log} | awk '{print $4}')
    both=$(grep "Input Read Pairs" ${log} | awk '{print $7}')
    forward=$(grep "Input Read Pairs" ${log} | awk '{print $12}')
    reverse=$(grep "Input Read Pairs" ${log} | awk '{print $17}')
    dropped=$(grep "Input Read Pairs" ${log} | awk '{print $20}')
    echo "${sample},${input},${both},${forward},${reverse},${dropped}" >> trimmomatic_summary.csv
done

echo "Trimmomatic batch processing complete!"
echo "Summary saved to: trimmomatic_summary.csv"
