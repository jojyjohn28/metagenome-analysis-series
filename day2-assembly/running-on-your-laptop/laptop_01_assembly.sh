#!/bin/bash
#
# Script: laptop_01_assembly.sh
# Description: Memory-efficient metagenome assembly for laptops (8-16GB RAM)
# Author: github.com/jojyjohn28
# Usage: bash laptop_01_assembly.sh

set -e

# Configuration
INPUT_DIR="../day1-qc-read-based/results/trimmed"
OUTPUT_DIR="results/assembly"
THREADS=4  # Adjust based on your CPU (use n-2 cores)
SAMPLE_NAME="sample1"  # Change to your sample name

# Create directories
mkdir -p ${OUTPUT_DIR}
mkdir -p logs

echo "========================================="
echo "  Laptop-Friendly Assembly with MEGAHIT"
echo "========================================="
echo "Sample: ${SAMPLE_NAME}"
echo "Using ${THREADS} CPU threads"
echo "Start time: $(date)"
echo ""

# Input files
R1="${INPUT_DIR}/${SAMPLE_NAME}_R1_paired.fastq.gz"
R2="${INPUT_DIR}/${SAMPLE_NAME}_R2_paired.fastq.gz"

# Check if input files exist
if [ ! -f "${R1}" ] || [ ! -f "${R2}" ]; then
    echo "ERROR: Input files not found!"
    echo "Expected:"
    echo "  ${R1}"
    echo "  ${R2}"
    exit 1
fi

# Check available memory
total_mem=$(free -g | awk '/^Mem:/{print $2}')
echo "Available RAM: ${total_mem} GB"

if [ ${total_mem} -lt 8 ]; then
    echo "WARNING: Less than 8GB RAM detected!"
    echo "Consider subsampling your data or using HPC resources"
    echo ""
fi

# Step 1: Assemble with MEGAHIT
echo "[1/3] Running MEGAHIT assembly..."
echo "This may take 2-4 hours depending on data size..."
echo ""

megahit \
    -1 ${R1} \
    -2 ${R2} \
    -o ${OUTPUT_DIR}/${SAMPLE_NAME}_megahit \
    -t ${THREADS} \
    --k-min 21 \
    --k-max 99 \
    --k-step 20 \
    --min-contig-len 500 \
    --memory 0.8 \
    2>&1 | tee logs/${SAMPLE_NAME}_assembly.log

if [ $? -eq 0 ]; then
    echo "✓ Assembly successful!"
else
    echo "✗ Assembly failed. Check logs/${SAMPLE_NAME}_assembly.log"
    exit 1
fi

# Step 2: Create easy-to-find copy
echo ""
echo "[2/3] Creating final contig file..."
cp ${OUTPUT_DIR}/${SAMPLE_NAME}_megahit/final.contigs.fa \
   ${OUTPUT_DIR}/${SAMPLE_NAME}_contigs.fasta

# Step 3: Basic statistics
echo ""
echo "[3/3] Calculating assembly statistics..."

total_contigs=$(grep -c "^>" ${OUTPUT_DIR}/${SAMPLE_NAME}_contigs.fasta)
longest_contig=$(awk '/^>/ {if (seqlen){print seqlen}; seqlen=0; next} {seqlen+=length($0)} END {print seqlen}' ${OUTPUT_DIR}/${SAMPLE_NAME}_contigs.fasta | sort -nr | head -1)

echo ""
echo "========================================="
echo "  Assembly Statistics"
echo "========================================="
echo "Sample: ${SAMPLE_NAME}"
echo "Total contigs: ${total_contigs}"
echo "Longest contig: ${longest_contig} bp"
echo ""

# Calculate total assembly length
total_length=$(awk '/^>/ {if (seqlen){print seqlen}; seqlen=0; next} {seqlen+=length($0)} END {print seqlen}' ${OUTPUT_DIR}/${SAMPLE_NAME}_contigs.fasta | awk '{sum+=$1} END {print sum}')
echo "Total assembly length: ${total_length} bp"

# Count contigs by size
echo ""
echo "Contigs by size:"
awk '/^>/ {if (seqlen){print seqlen}; seqlen=0; next} {seqlen+=length($0)} END {print seqlen}' ${OUTPUT_DIR}/${SAMPLE_NAME}_contigs.fasta | \
awk 'BEGIN {c500=0; c1k=0; c5k=0; c10k=0}
     {if ($1>=500) c500++; if ($1>=1000) c1k++; if ($1>=5000) c5k++; if ($1>=10000) c10k++}
     END {
         printf "  >= 500 bp:   %d\n", c500;
         printf "  >= 1,000 bp: %d\n", c1k;
         printf "  >= 5,000 bp: %d\n", c5k;
         printf "  >= 10,000 bp: %d\n", c10k
     }'

echo ""
echo "End time: $(date)"
echo ""
echo "========================================="
echo "  Assembly Complete!"
echo "========================================="
echo ""
echo "Output files:"
echo "  - ${OUTPUT_DIR}/${SAMPLE_NAME}_contigs.fasta"
echo "  - logs/${SAMPLE_NAME}_assembly.log"
echo ""
echo "Next steps:"
echo "  1. Calculate assembly quality:"
echo "     bash laptop_02_quality_check.sh"
echo "  2. Calculate coverage (for binning):"
echo "     bash laptop_03_calculate_coverage.sh"
echo ""
echo "💡 Tip: For better quality, consider running metaSPAdes"
echo "   on HPC if available (requires 64-128GB RAM)"
