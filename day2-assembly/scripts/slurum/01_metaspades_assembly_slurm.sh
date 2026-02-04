#!/bin/bash
#SBATCH --job-name=metaspades
#SBATCH --output=logs/slurm/metaspades_%j.out
#SBATCH --error=logs/slurm/metaspades_%j.err
#SBATCH --time=48:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=200G
#SBATCH --partition=compute

# Script: 01_metaspades_assembly_slurm.sh
# Description: Assemble metagenomes using metaSPAdes (SLURM version)
# Author: github.com/jojyjohn28
# Usage: sbatch 01_metaspades_assembly_slurm.sh

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
echo "Running on: ${SLURM_NODELIST}"
echo "CPUs: ${SLURM_CPUS_PER_TASK}"
echo "Memory: ${SLURM_MEM_PER_NODE}MB"
echo ""

# Process each sample
for R1 in ${INPUT_DIR}/*_R1_final.fastq.gz; do
    sample=$(basename ${R1} _R1_final.fastq.gz)
    R2="${INPUT_DIR}/${sample}_R2_final.fastq.gz"
    
    # Check if R2 exists
    if [ ! -f "${R2}" ]; then
        echo "WARNING: ${R2} not found, skipping ${sample}"
        continue
    fi
    
    echo "Assembling ${sample}..."
    echo "Start time: $(date)"
    
    # Run metaSPAdes
    metaspades.py \
        -1 ${R1} \
        -2 ${R2} \
        -o ${OUTPUT_DIR}/${sample} \
        -t ${THREADS} \
        -m ${MEMORY} \
        -k 21,33,55,77,99,127 \
        --cov-cutoff auto
    
    if [ $? -eq 0 ]; then
        echo "✓ Successfully assembled ${sample}"
        
        # Create symbolic links for easy access
        ln -sf ${OUTPUT_DIR}/${sample}/contigs.fasta \
               ${OUTPUT_DIR}/${sample}_contigs.fasta
        ln -sf ${OUTPUT_DIR}/${sample}/scaffolds.fasta \
               ${OUTPUT_DIR}/${sample}_scaffolds.fasta
        
        # Quick statistics
        echo ""
        echo "Assembly statistics for ${sample}:"
        grep "^>" ${OUTPUT_DIR}/${sample}/contigs.fasta | wc -l | \
            awk '{print "  Total contigs: " $1}'
        grep "^>" ${OUTPUT_DIR}/${sample}/contigs.fasta | \
            awk '{s+=length($0)} END {print "  Total length: " s " bp"}'
        
    else
        echo "✗ Assembly failed for ${sample}"
        echo "Check log: ${OUTPUT_DIR}/${sample}/spades.log"
    fi
    
    echo "End time: $(date)"
    echo ""
done

echo "========================================="
echo "  metaSPAdes Assembly Complete!"
echo "========================================="
echo "Output directory: ${OUTPUT_DIR}"
echo ""
echo "Next steps:"
echo "  1. Run MetaQUAST for quality assessment"
echo "  2. Calculate coverage (for Day 3 binning)"
