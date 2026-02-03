#!/bin/bash
#SBATCH --job-name=kneaddata
#SBATCH --output=logs/slurm/kneaddata_%j.out
#SBATCH --error=logs/slurm/kneaddata_%j.err
#SBATCH --time=08:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --partition=compute

# Script: 03_kneaddata_batch_slurm.sh
# Description: Remove host contamination using KneadData (SLURM version)
# Author: github.com/jojyjohn28
# Usage: sbatch 03_kneaddata_batch_slurm.sh

# Load modules
module load kneaddata/0.12.0
module load bowtie2/2.4.5

# Set variables
INPUT_DIR="trimmed"
OUTPUT_DIR="decontaminated"
DB_PATH="/path/to/databases/kneaddata_db/human_genome"
THREADS=${SLURM_CPUS_PER_TASK}

# Create directories
mkdir -p ${OUTPUT_DIR}
mkdir -p logs/kneaddata
mkdir -p logs/slurm

echo "Starting KneadData decontamination..."
echo "Job ID: ${SLURM_JOB_ID}"
echo "Running on node: ${SLURM_NODELIST}"
echo "CPUs: ${SLURM_CPUS_PER_TASK}"

# Process each sample
for R1 in ${INPUT_DIR}/*_R1_paired.fastq.gz; do
    sample=$(basename ${R1} _R1_paired.fastq.gz)
    R2="${INPUT_DIR}/${sample}_R2_paired.fastq.gz"
    
    echo "Removing host sequences from ${sample}..."
    
    kneaddata \
        --input ${R1} \
        --input ${R2} \
        --output ${OUTPUT_DIR}/${sample} \
        --reference-db ${DB_PATH} \
        --threads ${THREADS} \
        --bypass-trim \
        --log logs/kneaddata/${sample}.log
    
    # Rename output files for clarity
    mv ${OUTPUT_DIR}/${sample}/${sample}_R1_paired_kneaddata_paired_1.fastq \
       ${OUTPUT_DIR}/${sample}_R1_clean.fastq
    mv ${OUTPUT_DIR}/${sample}/${sample}_R1_paired_kneaddata_paired_2.fastq \
       ${OUTPUT_DIR}/${sample}_R2_clean.fastq
    
    # Compress
    gzip ${OUTPUT_DIR}/${sample}_R1_clean.fastq
    gzip ${OUTPUT_DIR}/${sample}_R2_clean.fastq
    
    echo "Completed ${sample}"
done

# Generate summary
echo "Generating read count summary..."
kneaddata_read_count_table \
    --input ${OUTPUT_DIR} \
    --output kneaddata_read_counts.txt

echo "KneadData batch processing complete!"
echo "Summary saved to: kneaddata_read_counts.txt"
