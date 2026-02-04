#!/bin/bash
#
# Script: laptop_02_quality_check.sh
# Description: Quick assembly quality assessment for laptops
# Author: github.com/jojyjohn28
# Usage: bash laptop_02_quality_check.sh

set -e

# Configuration
ASSEMBLY_DIR="results/assembly"
OUTPUT_DIR="results/quality"
SAMPLE_NAME="sample1"  # Change to your sample name
THREADS=4

# Create directories
mkdir -p ${OUTPUT_DIR}
mkdir -p logs

echo "========================================="
echo "  Assembly Quality Check"
echo "========================================="
echo "Sample: ${SAMPLE_NAME}"
echo ""

CONTIGS="${ASSEMBLY_DIR}/${SAMPLE_NAME}_contigs.fasta"

if [ ! -f "${CONTIGS}" ]; then
    echo "ERROR: Assembly not found: ${CONTIGS}"
    echo "Run laptop_01_assembly.sh first!"
    exit 1
fi

# Step 1: Run MetaQUAST (lightweight version)
echo "[1/2] Running MetaQUAST..."
echo "This may take 10-30 minutes..."
echo ""

metaquast.py ${CONTIGS} \
    -o ${OUTPUT_DIR}/${SAMPLE_NAME}_metaquast \
    -t ${THREADS} \
    --min-contig 500 \
    --fast \
    2>&1 | tee logs/${SAMPLE_NAME}_metaquast.log

if [ $? -eq 0 ]; then
    echo "✓ MetaQUAST completed!"
    echo "  Report: ${OUTPUT_DIR}/${SAMPLE_NAME}_metaquast/report.html"
else
    echo "✗ MetaQUAST failed"
fi

echo ""

# Step 2: Generate summary statistics
echo "[2/2] Generating summary statistics..."

python << 'EOF'
import sys
from Bio import SeqIO
from collections import Counter
import statistics

def analyze_assembly(fasta_file):
    lengths = []
    gc_contents = []
    
    for record in SeqIO.parse(fasta_file, "fasta"):
        length = len(record.seq)
        lengths.append(length)
        
        # Calculate GC content
        seq_upper = str(record.seq).upper()
        gc_count = seq_upper.count('G') + seq_upper.count('C')
        gc_percent = (gc_count / length * 100) if length > 0 else 0
        gc_contents.append(gc_percent)
    
    # Sort lengths for N50 calculation
    lengths_sorted = sorted(lengths, reverse=True)
    total_length = sum(lengths_sorted)
    
    # Calculate N50
    cumsum = 0
    n50 = 0
    l50 = 0
    for i, length in enumerate(lengths_sorted):
        cumsum += length
        if cumsum >= total_length / 2:
            n50 = length
            l50 = i + 1
            break
    
    # Calculate N75
    cumsum = 0
    n75 = 0
    for length in lengths_sorted:
        cumsum += length
        if cumsum >= total_length * 0.75:
            n75 = length
            break
    
    # Print results
    print("\n" + "="*50)
    print("  ASSEMBLY QUALITY METRICS")
    print("="*50)
    print(f"\nBasic Statistics:")
    print(f"  Total contigs:      {len(lengths):,}")
    print(f"  Total length:       {total_length:,} bp")
    print(f"  Largest contig:     {max(lengths):,} bp")
    print(f"  Smallest contig:    {min(lengths):,} bp")
    print(f"  Mean contig length: {statistics.mean(lengths):.0f} bp")
    print(f"  Median contig:      {statistics.median(lengths):.0f} bp")
    
    print(f"\nN-statistics:")
    print(f"  N50: {n50:,} bp")
    print(f"  L50: {l50:,} contigs")
    print(f"  N75: {n75:,} bp")
    
    print(f"\nGC Content:")
    print(f"  Mean GC%:   {statistics.mean(gc_contents):.2f}%")
    print(f"  Median GC%: {statistics.median(gc_contents):.2f}%")
    print(f"  Min GC%:    {min(gc_contents):.2f}%")
    print(f"  Max GC%:    {max(gc_contents):.2f}%")
    
    # Size distribution
    print(f"\nSize Distribution:")
    size_bins = {
        "500-1000 bp": sum(1 for l in lengths if 500 <= l < 1000),
        "1-5 kb":      sum(1 for l in lengths if 1000 <= l < 5000),
        "5-10 kb":     sum(1 for l in lengths if 5000 <= l < 10000),
        "10-50 kb":    sum(1 for l in lengths if 10000 <= l < 50000),
        ">50 kb":      sum(1 for l in lengths if l >= 50000)
    }
    for bin_name, count in size_bins.items():
        print(f"  {bin_name:12s}: {count:,} contigs ({count/len(lengths)*100:.1f}%)")

# Run analysis
analyze_assembly("${CONTIGS}")
EOF

echo ""
echo "========================================="
echo "  Quality Check Complete!"
echo "========================================="
echo ""
echo "Files created:"
echo "  - ${OUTPUT_DIR}/${SAMPLE_NAME}_metaquast/report.html"
echo "  - ${OUTPUT_DIR}/${SAMPLE_NAME}_metaquast/report.pdf"
echo ""
echo "View the HTML report in your browser:"
echo "  firefox ${OUTPUT_DIR}/${SAMPLE_NAME}_metaquast/report.html"
echo ""
echo "Next step: Calculate coverage for binning"
echo "  bash laptop_03_calculate_coverage.sh"
