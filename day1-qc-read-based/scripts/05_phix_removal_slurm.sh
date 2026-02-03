#!/bin/bash
#SBATCH --job-name=phix_removal
#SBATCH --output=logs/slurm/phix_%j.out
#SBATCH --error=logs/slurm/phix_%j.err
#SBATCH --time=04:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --partition=compute

# Script: 05_phix_removal_slurm.sh
# Description: Remove PhiX contamination using BBDuk (SLURM version)
# Author: github.com/jojyjohn28
# Usage: sbatch 05_phix_removal_slurm.sh

# Load modules
module load bbtools/38.90

# Set variables
INPUT_DIR="decontaminated"
OUTPUT_DIR="decontaminated_phix"
PHIX_REF="/path/to/bbmap/resources/phix174_ill.ref.fa.gz"
THREADS=${SLURM_CPUS_PER_TASK}

# Create output directory
mkdir -p ${OUTPUT_DIR}
mkdir -p logs/slurm

echo "Starting PhiX removal..."
echo "Job ID: ${SLURM_JOB_ID}"
echo "Running on node: ${SLURM_NODELIST}"
echo "CPUs: ${SLURM_CPUS_PER_TASK}"

# Process each sample
for R1 in ${INPUT_DIR}/*_R1_clean.fastq.gz; do
    sample=$(basename ${R1} _R1_clean.fastq.gz)
    R2="${INPUT_DIR}/${sample}_R2_clean.fastq.gz"
    
    echo "Removing PhiX from ${sample}..."
    
    bbduk.sh \
        in1=${R1} \
        in2=${R2} \
        out1=${OUTPUT_DIR}/${sample}_R1_final.fastq.gz \
        out2=${OUTPUT_DIR}/${sample}_R2_final.fastq.gz \
        outm1=${OUTPUT_DIR}/${sample}_R1_phix.fastq.gz \
        outm2=${OUTPUT_DIR}/${sample}_R2_phix.fastq.gz \
        ref=${PHIX_REF} \
        k=31 \
        hdist=1 \
        threads=${THREADS} \
        stats=${OUTPUT_DIR}/${sample}_phix_stats.txt
    
    echo "Completed ${sample}"
done

echo "PhiX removal complete!"
echo "Statistics saved in: ${OUTPUT_DIR}/*_phix_stats.txt"
