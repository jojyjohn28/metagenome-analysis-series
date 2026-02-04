#!/bin/bash
#SBATCH --job-name=metaspades
#SBATCH --output=logs/slurm/metaspades_%j.out
#SBATCH --error=logs/slurm/metaspades_%j.err
#SBATCH --time=48:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=200G
#SBATCH --partition=compute

# Script: 01_metaspades_assembly.sh
# Description: Assemble metagenome using metaSPAdes (SLURM)
# Author: github.com/jojyjohn28
# Usage: sbatch 01_metaspades_assembly.sh

# Load modules
module load spades/3.15.5

# Set variables
INPUT_DIR="../day1-qc-read-based/clean_reads"
OUTPUT_DIR="assemblies/metaspades"
THREADS=${SLURM_CPUS_PER_TASK}
MEMORY=200  # GB

# Create directories
mkdir -p ${OUTPUT_DIR}
mkdir -p logs/slurm

echo "========================================="
echo "  metaSPAdes Assembly"
echo "========================================="
echo "Job ID: ${SLURM_JOB_ID}"
echo "Node: ${SLURM_NODELIST}"
echo "CPUs: ${SLURM_CPUS_PER_TASK}"
echo "Memory: ${SLURM_MEM_PER_NODE}MB"
echo "Start time: $(date)"
echo ""

# Process each sample
for R1 in ${INPUT_DIR}/*_R1_final.fastq.gz; do
    sample=$(basename ${R1} _R1_final.fastq.gz)
    R2="${INPUT_DIR}/${sample}_R2_final.fastq.gz"
    
    echo "Assembling ${sample}..."
    echo "Input R1: ${R1}"
    echo "Input R2: ${R2}"
    echo "Output: ${OUTPUT_DIR}/${sample}"
    echo ""
    
    # Run metaSPAdes
    metaspades.py \
        -1 ${R1} \
        -2 ${R2} \
        -o ${OUTPUT_DIR}/${sample} \
        -t ${THREADS} \
        -m ${MEMORY} \
        -k 21,33,55,77,99,127 \
        --cov-cutoff auto \
        2>&1 | tee logs/${sample}_metaspades.log
    
    # Check if assembly was successful
    if [ -f "${OUTPUT_DIR}/${sample}/contigs.fasta" ]; then
        echo "✓ Assembly successful: ${sample}"
        
        # Filter contigs >= 500bp
        reformat.sh \
            in=${OUTPUT_DIR}/${sample}/contigs.fasta \
            out=${OUTPUT_DIR}/${sample}/contigs_500bp.fasta \
            minlength=500
        
        # Get basic stats
        echo ""
        echo "Assembly statistics for ${sample}:"
        grep "^>" ${OUTPUT_DIR}/${sample}/contigs.fasta | wc -l | \
            xargs echo "  Total contigs:"
        grep "^>" ${OUTPUT_DIR}/${sample}/contigs_500bp.fasta | wc -l | \
            xargs echo "  Contigs >=500bp:"
        
    else
        echo "✗ Assembly failed: ${sample}"
        echo "Check log file: logs/${sample}_metaspades.log"
    fi
    
    echo ""
    echo "Completed ${sample}"
    echo "========================================="
    echo ""
done

echo ""
echo "metaSPAdes assembly complete!"
echo "End time: $(date)"
echo ""
echo "Next steps:"
echo "  1. Run MetaQUAST: sbatch 03_metaquast_assessment.sh"
echo "  2. Calculate coverage: sbatch 04_calculate_coverage.sh"
