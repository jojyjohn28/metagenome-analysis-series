#!/bin/bash
#SBATCH --job-name=metaphlan
#SBATCH --output=logs/slurm/metaphlan_%j.out
#SBATCH --error=logs/slurm/metaphlan_%j.err
#SBATCH --time=08:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=32G
#SBATCH --partition=compute

# Script: 10_metaphlan_profiling_slurm.sh
# Description: Taxonomic profiling using MetaPhlAn (SLURM version)
# Author: github.com/jojyjohn28
# Usage: sbatch 10_metaphlan_profiling_slurm.sh

# Load modules
module load metaphlan/4.0
module load bowtie2/2.4.5

# Set variables
INPUT_DIR="decontaminated_phix"
OUTPUT_DIR="taxonomy/metaphlan"
THREADS=${SLURM_CPUS_PER_TASK}

# Create output directories
mkdir -p ${OUTPUT_DIR}
mkdir -p ${OUTPUT_DIR}/bowtie2
mkdir -p logs/slurm

echo "Starting MetaPhlAn taxonomic profiling..."
echo "Job ID: ${SLURM_JOB_ID}"
echo "Running on node: ${SLURM_NODELIST}"
echo "CPUs: ${SLURM_CPUS_PER_TASK}"

# Process each sample
for R1 in ${INPUT_DIR}/*_R1_final.fastq.gz; do
    sample=$(basename ${R1} _R1_final.fastq.gz)
    R2="${INPUT_DIR}/${sample}_R2_final.fastq.gz"
    
    echo "Running MetaPhlAn on ${sample}..."
    
    # Run MetaPhlAn
    metaphlan \
        ${R1},${R2} \
        --input_type fastq \
        --nproc ${THREADS} \
        --bowtie2out ${OUTPUT_DIR}/bowtie2/${sample}.bt2.bz2 \
        --output_file ${OUTPUT_DIR}/${sample}_profile.txt \
        --unclassified_estimation
    
    echo "Completed ${sample}"
done

# Merge all profiles
echo "Merging all profiles..."
merge_metaphlan_tables.py \
    ${OUTPUT_DIR}/*_profile.txt \
    > ${OUTPUT_DIR}/merged_abundance_table.txt

# Generate species-only table
echo "Generating species-only table..."
grep -E "s__|clade_name" ${OUTPUT_DIR}/merged_abundance_table.txt \
    | grep -v "t__" \
    > ${OUTPUT_DIR}/merged_abundance_table_species.txt

echo "MetaPhlAn analysis complete!"
echo "Merged table: ${OUTPUT_DIR}/merged_abundance_table.txt"
echo "Species table: ${OUTPUT_DIR}/merged_abundance_table_species.txt"
