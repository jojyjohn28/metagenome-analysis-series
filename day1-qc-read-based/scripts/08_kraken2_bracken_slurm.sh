#!/bin/bash
#SBATCH --job-name=kraken2
#SBATCH --output=logs/slurm/kraken2_%j.out
#SBATCH --error=logs/slurm/kraken2_%j.err
#SBATCH --time=08:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=80G
#SBATCH --partition=compute

# Script: 08_kraken2_bracken_slurm.sh
# Description: Taxonomic profiling using Kraken2 and Bracken (SLURM version)
# Author: github.com/jojyjohn28
# Usage: sbatch 08_kraken2_bracken_slurm.sh

# Load modules
module load kraken2/2.1.2
module load bracken/2.7

# Set variables
INPUT_DIR="decontaminated_phix"
OUTPUT_DIR="taxonomy/kraken2"
KRAKEN_DB="databases/kraken2/kraken2_custom"
THREADS=${SLURM_CPUS_PER_TASK}

# Create output directory
mkdir -p ${OUTPUT_DIR}
mkdir -p logs/slurm

echo "Starting Kraken2/Bracken analysis..."
echo "Job ID: ${SLURM_JOB_ID}"
echo "Running on node: ${SLURM_NODELIST}"
echo "CPUs: ${SLURM_CPUS_PER_TASK}"
echo "Memory: ${SLURM_MEM_PER_NODE}MB"

# Process each sample
for R1 in ${INPUT_DIR}/*_R1_final.fastq.gz; do
    sample=$(basename ${R1} _R1_final.fastq.gz)
    R2="${INPUT_DIR}/${sample}_R2_final.fastq.gz"
    
    echo "Running Kraken2 on ${sample}..."
    
    # Run Kraken2
    kraken2 \
        --db ${KRAKEN_DB} \
        --threads ${THREADS} \
        --paired ${R1} ${R2} \
        --output ${OUTPUT_DIR}/${sample}.kraken \
        --report ${OUTPUT_DIR}/${sample}.report \
        --confidence 0.1 \
        --minimum-base-quality 20
    
    echo "Running Bracken on ${sample}..."
    
    # Generate Bracken estimates at species level
    bracken \
        -d ${KRAKEN_DB} \
        -i ${OUTPUT_DIR}/${sample}.report \
        -o ${OUTPUT_DIR}/${sample}_bracken_species.txt \
        -w ${OUTPUT_DIR}/${sample}_bracken_species.report \
        -r 150 \
        -l S \
        -t 10
    
    # Generate Bracken estimates at genus level
    bracken \
        -d ${KRAKEN_DB} \
        -i ${OUTPUT_DIR}/${sample}.report \
        -o ${OUTPUT_DIR}/${sample}_bracken_genus.txt \
        -w ${OUTPUT_DIR}/${sample}_bracken_genus.report \
        -r 150 \
        -l G \
        -t 10
    
    echo "Completed ${sample}"
done

# Combine Bracken reports
echo "Combining Bracken reports..."

if command -v combine_bracken_outputs.py &> /dev/null; then
    combine_bracken_outputs.py \
        --files ${OUTPUT_DIR}/*_bracken_species.txt \
        -o ${OUTPUT_DIR}/bracken_species_combined.txt
    
    combine_bracken_outputs.py \
        --files ${OUTPUT_DIR}/*_bracken_genus.txt \
        -o ${OUTPUT_DIR}/bracken_genus_combined.txt
else
    echo "Warning: combine_bracken_outputs.py not found. Skipping report combination."
fi

echo "Kraken2/Bracken analysis complete!"
echo "Reports saved in: ${OUTPUT_DIR}/"
