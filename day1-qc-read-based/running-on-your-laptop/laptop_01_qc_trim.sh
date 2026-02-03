#!/bin/bash
#
# Script: laptop_01_qc_trim.sh
# Description: Lightweight QC and trimming for laptop/desktop (8GB+ RAM)
# Author: github.com/jojyjohn28
# Usage: bash laptop_01_qc_trim.sh

set -e  # Exit on error

# Configuration
INPUT_DIR="raw_data"
OUTPUT_DIR="results"
THREADS=4  # Adjust based on your CPU (use n-2 of your total cores)

# Create directories
mkdir -p ${OUTPUT_DIR}/fastqc_raw
mkdir -p ${OUTPUT_DIR}/trimmed
mkdir -p ${OUTPUT_DIR}/fastqc_trimmed
mkdir -p logs

echo "========================================="
echo "  Laptop-Friendly QC & Trimming Pipeline"
echo "========================================="
echo "Using ${THREADS} CPU threads"
echo "Input: ${INPUT_DIR}"
echo "Output: ${OUTPUT_DIR}"
echo ""

# Step 1: Initial QC
echo "[1/4] Running FastQC on raw reads..."
echo "  This may take 5-15 minutes..."
fastqc -o ${OUTPUT_DIR}/fastqc_raw \
       -t ${THREADS} \
       ${INPUT_DIR}/*.fastq.gz

echo "  ✓ FastQC complete"

# Step 2: Trimming
echo ""
echo "[2/4] Running Trimmomatic..."
echo "  Processing each sample..."

for R1 in ${INPUT_DIR}/*_R1.fastq.gz; do
    sample=$(basename ${R1} _R1.fastq.gz)
    R2="${INPUT_DIR}/${sample}_R2.fastq.gz"
    
    # Check if R2 exists
    if [ ! -f "${R2}" ]; then
        echo "  WARNING: ${R2} not found, skipping ${sample}"
        continue
    fi
    
    echo "  Processing ${sample}..."
    
    trimmomatic PE \
        -threads ${THREADS} \
        -phred33 \
        ${R1} ${R2} \
        ${OUTPUT_DIR}/trimmed/${sample}_R1_paired.fastq.gz \
        ${OUTPUT_DIR}/trimmed/${sample}_R1_unpaired.fastq.gz \
        ${OUTPUT_DIR}/trimmed/${sample}_R2_paired.fastq.gz \
        ${OUTPUT_DIR}/trimmed/${sample}_R2_unpaired.fastq.gz \
        ILLUMINACLIP:TruSeq3-PE.fa:2:30:10:2:True \
        LEADING:3 \
        TRAILING:3 \
        SLIDINGWINDOW:4:15 \
        MINLEN:36 \
        2> logs/${sample}_trimmomatic.log
    
    # Extract and display statistics
    if [ -f "logs/${sample}_trimmomatic.log" ]; then
        surviving=$(grep "Input Read Pairs" logs/${sample}_trimmomatic.log | awk '{print $7}' | sed 's/(//')
        echo "    Surviving pairs: ${surviving}%"
    fi
done

echo "  ✓ Trimmomatic complete"

# Step 3: Post-trimming QC
echo ""
echo "[3/4] Running FastQC on trimmed reads..."
fastqc -o ${OUTPUT_DIR}/fastqc_trimmed \
       -t ${THREADS} \
       ${OUTPUT_DIR}/trimmed/*_paired.fastq.gz

echo "  ✓ FastQC complete"

# Step 4: Generate reports
echo ""
echo "[4/4] Generating MultiQC reports..."
multiqc ${OUTPUT_DIR}/fastqc_raw \
        -o ${OUTPUT_DIR} \
        -n raw_multiqc_report \
        --quiet

multiqc ${OUTPUT_DIR}/fastqc_trimmed \
        -o ${OUTPUT_DIR} \
        -n trimmed_multiqc_report \
        --quiet

echo "  ✓ MultiQC reports generated"

# Summary
echo ""
echo "========================================="
echo "  QC and Trimming Complete!"
echo "========================================="
echo ""
echo "Results saved in: ${OUTPUT_DIR}/"
echo ""
echo "Next steps:"
echo "  1. View QC reports:"
echo "     - ${OUTPUT_DIR}/raw_multiqc_report.html"
echo "     - ${OUTPUT_DIR}/trimmed_multiqc_report.html"
echo ""
echo "  2. Run taxonomic profiling:"
echo "     bash laptop_02_taxonomy.sh"
echo ""
