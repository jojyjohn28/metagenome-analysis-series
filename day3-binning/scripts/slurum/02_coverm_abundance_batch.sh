#!/bin/bash
#SBATCH --job-name=coverm_abundance
#SBATCH --output=logs/coverm_abundance_%j.out
#SBATCH --error=logs/coverm_abundance_%j.err
#SBATCH --time=12:00:00
#SBATCH --cpus-per-task=96
#SBATCH --mem=128G
#SBATCH --partition=compute

# CoverM MAG Abundance Analysis
# Author: github.com/jojyjohn28
# Description: Calculate MAG abundance across all samples using CoverM
# Usage: sbatch 02_coverm_abundance_batch.sh

set -e  # Exit on error

# ==================== CONFIGURATION ====================

# Directories
CLEAN_READS_DIR="/path/to/clean_reads"
MAG_DIR="/path/to/metawrap_binning/sample1/BIN_REFINEMENT/metawrap_50_10_bins"
OUTPUT_DIR="mag_abundance"

# Sample list
SAMPLES=(
    "sample1"
    "sample2"
    "sample3"
)

# CoverM parameters
THREADS=${SLURM_CPUS_PER_TASK:-96}
MIN_COVERED_FRACTION=0.1

# ==================== SETUP ====================

mkdir -p ${OUTPUT_DIR}
mkdir -p logs

# Load environment
module load anaconda3
source activate metawrap

# Verify CoverM is installed
if ! command -v coverm &> /dev/null; then
    echo "ERROR: CoverM not found. Install with: conda install -c bioconda coverm"
    exit 1
fi

echo "========================================="
echo "  CoverM MAG Abundance Analysis"
echo "========================================="
echo "Job ID: ${SLURM_JOB_ID}"
echo "Node: ${SLURMD_NODENAME}"
echo "CPUs: ${THREADS}"
echo "Samples: ${#SAMPLES[@]}"
echo "MAG directory: ${MAG_DIR}"
echo "Start time: $(date)"
echo ""

# ==================== BUILD READ PAIRS ====================

echo "Building read pair list..."
READ_PAIRS=""
for sample in "${SAMPLES[@]}"; do
    R1="${CLEAN_READS_DIR}/${sample}_R1.fastq.gz"
    R2="${CLEAN_READS_DIR}/${sample}_R2.fastq.gz"
    
    # Check if files exist
    if [ ! -f "${R1}" ] || [ ! -f "${R2}" ]; then
        echo "WARNING: Reads not found for ${sample}, skipping..."
        continue
    fi
    
    READ_PAIRS="${READ_PAIRS} ${R1} ${R2}"
    echo "  Added: ${sample}"
done

echo ""

# ==================== RUN COVERM ====================

echo "Running CoverM genome mode..."
echo "Methods: relative_abundance, mean, trimmed_mean, covered_fraction, variance, rpkm"
echo ""

coverm genome \
    --coupled ${READ_PAIRS} \
    --genome-fasta-directory ${MAG_DIR} \
    --genome-fasta-extension fa \
    --output-file ${OUTPUT_DIR}/mag_abundance_table.tsv \
    --threads ${THREADS} \
    --methods relative_abundance mean trimmed_mean covered_fraction variance rpkm \
    --min-covered-fraction ${MIN_COVERED_FRACTION} \
    2>&1 | tee ${OUTPUT_DIR}/coverm.log

if [ $? -eq 0 ]; then
    echo "✓ CoverM analysis completed successfully"
else
    echo "✗ CoverM analysis failed"
    exit 1
fi

echo ""

# ==================== EXTRACT KEY METRICS ====================

echo "Extracting key metrics..."

# Extract relative abundance only
echo "Creating relative abundance table..."
head -n 1 ${OUTPUT_DIR}/mag_abundance_table.tsv > ${OUTPUT_DIR}/relative_abundance.tsv
grep "Relative Abundance" ${OUTPUT_DIR}/mag_abundance_table.tsv | \
    cut -f1,$(seq -s, 2 3 $(head -1 ${OUTPUT_DIR}/mag_abundance_table.tsv | awk '{print NF}')) | \
    tr ',' '\t' >> ${OUTPUT_DIR}/relative_abundance.tsv

# Extract mean coverage
echo "Creating mean coverage table..."
head -n 1 ${OUTPUT_DIR}/mag_abundance_table.tsv > ${OUTPUT_DIR}/mean_coverage.tsv
grep "Mean" ${OUTPUT_DIR}/mag_abundance_table.tsv | grep -v "Trimmed" | \
    cut -f1,$(seq -s, 2 3 $(head -1 ${OUTPUT_DIR}/mag_abundance_table.tsv | awk '{print NF}')) | \
    tr ',' '\t' >> ${OUTPUT_DIR}/mean_coverage.tsv

# Extract covered fraction
echo "Creating covered fraction table..."
head -n 1 ${OUTPUT_DIR}/mag_abundance_table.tsv > ${OUTPUT_DIR}/covered_fraction.tsv
grep "Covered Fraction" ${OUTPUT_DIR}/mag_abundance_table.tsv | \
    cut -f1,$(seq -s, 2 3 $(head -1 ${OUTPUT_DIR}/mag_abundance_table.tsv | awk '{print NF}')) | \
    tr ',' '\t' >> ${OUTPUT_DIR}/covered_fraction.tsv

echo "✓ Metric tables created"
echo ""

# ==================== SUMMARY STATISTICS ====================

echo "Generating summary statistics..."

python3 << 'EOF'
import pandas as pd
import numpy as np

# Read abundance table
df = pd.read_csv('mag_abundance/mag_abundance_table.tsv', sep='\t')

# Extract relative abundance columns
ra_cols = [col for col in df.columns if 'Relative Abundance' in col]
ra_data = df[ra_cols]

print("\n" + "="*70)
print("  MAG ABUNDANCE SUMMARY")
print("="*70)
print(f"\nTotal MAGs: {len(df)}")
print(f"Total samples: {len(ra_cols)}")
print(f"\nRelative Abundance Statistics:")
print(f"  Mean across all MAGs: {ra_data.mean().mean():.2f}%")
print(f"  Median across all MAGs: {ra_data.median().median():.2f}%")
print(f"  Max abundance: {ra_data.max().max():.2f}%")
print(f"\nMAG Detection:")
print(f"  MAGs with >10% abundance in any sample: {(ra_data > 10).any(axis=1).sum()}")
print(f"  MAGs with >5% abundance in any sample: {(ra_data > 5).any(axis=1).sum()}")
print(f"  MAGs with >1% abundance in any sample: {(ra_data > 1).any(axis=1).sum()}")
print(f"  MAGs with <0.1% abundance in all samples: {(ra_data < 0.1).all(axis=1).sum()}")
print("\nTop 5 Most Abundant MAGs (mean across samples):")
top5 = df[['Genome'] + ra_cols].set_index('Genome')
top5['Mean_RA'] = top5.mean(axis=1)
print(top5.nlargest(5, 'Mean_RA')[['Mean_RA']])
print("="*70)
EOF

echo ""

# ==================== OUTPUT FILES ====================

echo "Output files created:"
echo "  ${OUTPUT_DIR}/mag_abundance_table.tsv      - Full abundance table"
echo "  ${OUTPUT_DIR}/relative_abundance.tsv       - Relative abundance only"
echo "  ${OUTPUT_DIR}/mean_coverage.tsv            - Mean coverage only"
echo "  ${OUTPUT_DIR}/covered_fraction.tsv         - Covered fraction only"
echo ""

echo "========================================="
echo "  CoverM Analysis Complete!"
echo "========================================="
echo "End time: $(date)"
echo ""
echo "Next steps:"
echo "  1. Run SingleM for coverage validation: sbatch 03_singlem_coverage_batch.sh"
echo "  2. Visualize results: python scripts/analysis/visualize_mag_abundance.py"
