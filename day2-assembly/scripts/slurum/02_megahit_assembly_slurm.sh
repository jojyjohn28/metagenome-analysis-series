#!/bin/bash
#SBATCH --job-name=megahit
#SBATCH --output=logs/slurm/megahit_%j.out
#SBATCH --error=logs/slurm/megahit_%j.err
#SBATCH --time=12:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=64G
#SBATCH --partition=compute

# Script: 02_megahit_assembly_slurm.sh
# Description: Assemble metagenomes using MEGAHIT (SLURM version)
# Author: github.com/jojyjohn28
# Usage: sbatch 02_megahit_assembly_slurm.sh

# Load modules
module load megahit/1.2.9

# Set variables
INPUT_DIR="../day1-qc-read-based/clean_reads"
OUTPUT_DIR="assemblies/megahit"
THREADS=${SLURM_CPUS_PER_TASK}
MEMORY=0.9  # Use 90% of available memory

# Create directories
mkdir -p ${OUTPUT_DIR}
mkdir -p logs/slurm

echo "========================================="
echo "  MEGAHIT Assembly"
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
    
    if [ ! -f "${R2}" ]; then
        echo "WARNING: ${R2} not found, skipping ${sample}"
        continue
    fi
    
    echo "Assembling ${sample}..."
    echo "Start time: $(date)"
    
    # Remove output directory if exists (MEGAHIT won't overwrite)
    if [ -d "${OUTPUT_DIR}/${sample}" ]; then
        echo "Removing existing directory: ${OUTPUT_DIR}/${sample}"
        rm -rf ${OUTPUT_DIR}/${sample}
    fi
    
    # Run MEGAHIT
    megahit \
        -1 ${R1} \
        -2 ${R2} \
        -o ${OUTPUT_DIR}/${sample} \
        -t ${THREADS} \
        -m ${MEMORY} \
        --k-min 21 \
        --k-max 141 \
        --k-step 20 \
        --min-contig-len 500 \
        --presets meta-sensitive
    
    if [ $? -eq 0 ]; then
        echo "✓ Successfully assembled ${sample}"
        
        # Rename final contigs for consistency
        cp ${OUTPUT_DIR}/${sample}/final.contigs.fa \
           ${OUTPUT_DIR}/${sample}_contigs.fasta
        
        # Quick statistics
        echo ""
        echo "Assembly statistics for ${sample}:"
        grep "^>" ${OUTPUT_DIR}/${sample}/final.contigs.fa | wc -l | \
            awk '{print "  Total contigs: " $1}'
        
    else
        echo "✗ Assembly failed for ${sample}"
        echo "Check log: ${OUTPUT_DIR}/${sample}/log"
    fi
    
    echo "End time: $(date)"
    echo ""
done

echo "========================================="
echo "  MEGAHIT Assembly Complete!"
echo "========================================="
echo "Output directory: ${OUTPUT_DIR}"
echo ""
echo "Comparison with metaSPAdes:"
echo "  MEGAHIT: Faster, lower memory"
echo "  metaSPAdes: Higher quality, better N50"
echo ""
echo "Next step: Run MetaQUAST to compare assemblies"
