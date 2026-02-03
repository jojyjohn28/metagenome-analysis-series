#!/bin/bash
#SBATCH --job-name=kaiju
#SBATCH --output=logs/slurm/kaiju_%j.out
#SBATCH --error=logs/slurm/kaiju_%j.err
#SBATCH --time=12:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=120G
#SBATCH --partition=compute

# Script: 07_kaiju_profiling_slurm.sh
# Description: Taxonomic profiling using Kaiju (SLURM version)
# Author: github.com/jojyjohn28
# Usage: sbatch 07_kaiju_profiling_slurm.sh

# Load modules
module load kaiju/1.9.0
module load krona/2.8

# Set variables
INPUT_DIR="decontaminated_phix"
OUTPUT_DIR="taxonomy/kaiju"
KAIJU_DB="databases/kaiju/kaiju_db_nr.fmi"
NODES="databases/kaiju/nodes.dmp"
NAMES="databases/kaiju/names.dmp"
THREADS=${SLURM_CPUS_PER_TASK}

# Create output directory
mkdir -p ${OUTPUT_DIR}
mkdir -p logs/slurm

echo "Starting Kaiju taxonomic profiling..."
echo "Job ID: ${SLURM_JOB_ID}"
echo "Running on node: ${SLURM_NODELIST}"
echo "CPUs: ${SLURM_CPUS_PER_TASK}"
echo "Memory: ${SLURM_MEM_PER_NODE}MB"

# Process each sample
for R1 in ${INPUT_DIR}/*_R1_final.fastq.gz; do
    sample=$(basename ${R1} _R1_final.fastq.gz)
    R2="${INPUT_DIR}/${sample}_R2_final.fastq.gz"
    
    echo "Running Kaiju on ${sample}..."
    
    # Run Kaiju classification
    kaiju \
        -t ${NODES} \
        -f ${KAIJU_DB} \
        -i ${R1} \
        -j ${R2} \
        -o ${OUTPUT_DIR}/${sample}.out \
        -z ${THREADS} \
        -v
    
    # Generate summary at different taxonomic levels
    for level in phylum class order family genus species; do
        echo "  Generating ${level}-level summary..."
        kaiju2table \
            -t ${NODES} \
            -n ${NAMES} \
            -r ${level} \
            -o ${OUTPUT_DIR}/${sample}_${level}.tsv \
            ${OUTPUT_DIR}/${sample}.out
    done
    
    # Generate Krona plot
    echo "  Generating Krona plot..."
    kaiju2krona \
        -t ${NODES} \
        -n ${NAMES} \
        -i ${OUTPUT_DIR}/${sample}.out \
        -o ${OUTPUT_DIR}/${sample}.krona
    
    ktImportText \
        -o ${OUTPUT_DIR}/${sample}_krona.html \
        ${OUTPUT_DIR}/${sample}.krona
    
    echo "Completed ${sample}"
done

# Combine all samples into a single table
echo "Combining all samples..."
kaiju2table \
    -t ${NODES} \
    -n ${NAMES} \
    -r genus \
    -o ${OUTPUT_DIR}/all_samples_genus.tsv \
    ${OUTPUT_DIR}/*.out

echo "Kaiju analysis complete!"
echo "Combined table: ${OUTPUT_DIR}/all_samples_genus.tsv"
