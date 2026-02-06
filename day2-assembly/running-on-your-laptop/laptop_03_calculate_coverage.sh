#!/bin/bash
#
# Script: laptop_03_calculate_coverage.sh
# Description: Calculate contig coverage for binning (laptop-optimized)
# Author: github.com/jojyjohn28
# Usage: bash laptop_03_calculate_coverage.sh

set -e

# Configuration
ASSEMBLY_DIR="results/assembly"
OUTPUT_DIR="results/coverage"
SAMPLE_NAME="sample1"  # Change to your sample name
THREADS=4

# Clean reads from Day 1
READS_DIR="../day1-qc-read-based/results/trimmed"
R1="${READS_DIR}/${SAMPLE_NAME}_R1_paired.fastq.gz"
R2="${READS_DIR}/${SAMPLE_NAME}_R2_paired.fastq.gz"

# Assembled contigs
CONTIGS="${ASSEMBLY_DIR}/${SAMPLE_NAME}_contigs.fasta"

# Create directories
mkdir -p ${OUTPUT_DIR}
mkdir -p logs

echo "========================================="
echo "  Contig Coverage Calculation"
echo "========================================="
echo "Sample: ${SAMPLE_NAME}"
echo "Threads: ${THREADS}"
echo ""

# Verify files exist
if [ ! -f "${CONTIGS}" ]; then
    echo "ERROR: Assembly not found: ${CONTIGS}"
    echo "Run laptop_01_assembly.sh first!"
    exit 1
fi

if [ ! -f "${R1}" ] || [ ! -f "${R2}" ]; then
    echo "ERROR: Clean reads not found!"
    echo "Expected:"
    echo "  ${R1}"
    echo "  ${R2}"
    exit 1
fi

# Check available disk space
available_space=$(df -h . | awk 'NR==2 {print $4}')
echo "Available disk space: ${available_space}"
echo ""

# Step 1: Build Bowtie2 index
echo "[1/4] Building Bowtie2 index..."
echo "This may take 5-10 minutes..."
echo ""

bowtie2-build \
    --threads ${THREADS} \
    ${CONTIGS} \
    ${OUTPUT_DIR}/${SAMPLE_NAME}_index \
    2>&1 | tee logs/${SAMPLE_NAME}_bowtie2_build.log

if [ $? -eq 0 ]; then
    echo "✓ Index built successfully"
else
    echo "✗ Index building failed"
    exit 1
fi

echo ""

# Step 2: Map reads to contigs
echo "[2/4] Mapping reads to contigs..."
echo "This is the longest step - may take 30-90 minutes..."
echo "You can monitor progress in another terminal with:"
echo "  tail -f logs/${SAMPLE_NAME}_mapping.log"
echo ""

bowtie2 \
    -x ${OUTPUT_DIR}/${SAMPLE_NAME}_index \
    -1 ${R1} \
    -2 ${R2} \
    -p ${THREADS} \
    --no-unal \
    2> logs/${SAMPLE_NAME}_mapping.log | \
samtools view -bS - | \
samtools sort -@ ${THREADS} -o ${OUTPUT_DIR}/${SAMPLE_NAME}.bam -

if [ $? -eq 0 ]; then
    echo "✓ Mapping completed"
else
    echo "✗ Mapping failed"
    echo "Check log: logs/${SAMPLE_NAME}_mapping.log"
    exit 1
fi

echo ""

# Step 3: Index BAM file
echo "[3/4] Indexing BAM file..."

samtools index ${OUTPUT_DIR}/${SAMPLE_NAME}.bam

if [ $? -eq 0 ]; then
    echo "✓ BAM file indexed"
else
    echo "✗ BAM indexing failed"
    exit 1
fi

echo ""

# Step 4: Calculate depth
echo "[4/4] Calculating coverage depth..."

samtools depth ${OUTPUT_DIR}/${SAMPLE_NAME}.bam > ${OUTPUT_DIR}/${SAMPLE_NAME}_depth.txt

if [ $? -eq 0 ]; then
    echo "✓ Coverage depth calculated"
else
    echo "✗ Depth calculation failed"
    exit 1
fi

# Get mapping statistics
echo ""
echo "========================================="
echo "  Mapping Statistics"
echo "========================================="
samtools flagstat ${OUTPUT_DIR}/${SAMPLE_NAME}.bam

# Calculate summary statistics
echo ""
echo "Coverage Summary:"
awk '{sum+=$3; count++} END {
    if (count>0) 
        printf "  Average depth: %.2f\n  Bases with coverage: %d\n", sum/count, count
}' ${OUTPUT_DIR}/${SAMPLE_NAME}_depth.txt

echo ""
echo "========================================="
echo "  Coverage Calculation Complete!"
echo "========================================="
echo ""
echo "Files created:"
echo "  - ${OUTPUT_DIR}/${SAMPLE_NAME}.bam"
echo "  - ${OUTPUT_DIR}/${SAMPLE_NAME}.bam.bai"
echo "  - ${OUTPUT_DIR}/${SAMPLE_NAME}_depth.txt"
echo ""
echo "These files are required for Day 3 binning!"
echo ""
echo "File sizes:"
ls -lh ${OUTPUT_DIR}/${SAMPLE_NAME}.bam
ls -lh ${OUTPUT_DIR}/${SAMPLE_NAME}_depth.txt
echo ""
echo "Next step: Day 3 - Genome Binning"
echo "  You can now move to Day 3 with these files."
