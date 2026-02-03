#!/bin/bash
#
# Script: laptop_02_taxonomy.sh
# Description: Lightweight taxonomic profiling with MetaPhlAn (8-16 GB RAM)
# Author: github.com/jojyjohn28
# Usage: bash laptop_02_taxonomy.sh

set -e

# Configuration
INPUT_DIR="results/trimmed"
OUTPUT_DIR="results/taxonomy"
THREADS=4  # Adjust based on your CPU

# Create directories
mkdir -p ${OUTPUT_DIR}/metaphlan
mkdir -p ${OUTPUT_DIR}/metaphlan/bowtie2
mkdir -p logs

echo "========================================="
echo "  Taxonomic Profiling with MetaPhlAn"
echo "========================================="
echo "Using ${THREADS} CPU threads"
echo "Input: ${INPUT_DIR}"
echo "Output: ${OUTPUT_DIR}"
echo ""

# Check if MetaPhlAn is installed
if ! command -v metaphlan &> /dev/null; then
    echo "ERROR: MetaPhlAn not found!"
    echo "Install with: conda install -c bioconda metaphlan"
    exit 1
fi

# Download database if first run
echo "Checking MetaPhlAn database..."
metaphlan --install 2>/dev/null || true
echo "  ✓ Database ready"
echo ""

# Count samples
sample_count=$(ls ${INPUT_DIR}/*_R1_paired.fastq.gz 2>/dev/null | wc -l)
echo "Found ${sample_count} samples to process"
echo ""

# Process each sample
counter=1
for R1 in ${INPUT_DIR}/*_R1_paired.fastq.gz; do
    sample=$(basename ${R1} _R1_paired.fastq.gz)
    R2="${INPUT_DIR}/${sample}_R2_paired.fastq.gz"
    
    # Check if R2 exists
    if [ ! -f "${R2}" ]; then
        echo "WARNING: ${R2} not found, skipping ${sample}"
        continue
    fi
    
    echo "[${counter}/${sample_count}] Profiling ${sample}..."
    echo "  This may take 30 minutes to 2 hours depending on data size..."
    
    # Run MetaPhlAn
    metaphlan \
        ${R1},${R2} \
        --input_type fastq \
        --nproc ${THREADS} \
        --bowtie2out ${OUTPUT_DIR}/metaphlan/bowtie2/${sample}.bt2.bz2 \
        --output_file ${OUTPUT_DIR}/metaphlan/${sample}_profile.txt \
        2> logs/${sample}_metaphlan.log
    
    # Quick statistics
    if [ -f "${OUTPUT_DIR}/metaphlan/${sample}_profile.txt" ]; then
        species_count=$(grep -c "s__" ${OUTPUT_DIR}/metaphlan/${sample}_profile.txt || true)
        echo "  ✓ Complete: ${species_count} species detected"
    fi
    
    counter=$((counter + 1))
    echo ""
done

# Merge profiles
echo "Merging all sample profiles..."
if [ $(ls ${OUTPUT_DIR}/metaphlan/*_profile.txt 2>/dev/null | wc -l) -gt 0 ]; then
    merge_metaphlan_tables.py \
        ${OUTPUT_DIR}/metaphlan/*_profile.txt \
        > ${OUTPUT_DIR}/metaphlan/merged_abundance_table.txt
    
    echo "  ✓ Merged table created"
    
    # Extract species-level only
    grep -E "s__|clade_name" ${OUTPUT_DIR}/metaphlan/merged_abundance_table.txt \
        | grep -v "t__" \
        > ${OUTPUT_DIR}/metaphlan/merged_species.txt
    
    echo "  ✓ Species-level table created"
else
    echo "  WARNING: No profiles found to merge!"
fi

echo ""
echo "========================================="
echo "  Taxonomic Profiling Complete!"
echo "========================================="
echo ""
echo "Results saved in: ${OUTPUT_DIR}/metaphlan/"
echo ""
echo "Files created:"
echo "  - Individual profiles: ${OUTPUT_DIR}/metaphlan/*_profile.txt"
echo "  - Merged table: ${OUTPUT_DIR}/metaphlan/merged_abundance_table.txt"
echo "  - Species table: ${OUTPUT_DIR}/metaphlan/merged_species.txt"
echo ""
echo "Next steps:"
echo "  1. Visualize results:"
echo "     Rscript laptop_03_visualize.R"
echo ""
echo "  2. View species table:"
echo "     column -t ${OUTPUT_DIR}/metaphlan/merged_species.txt | less -S"
echo ""
