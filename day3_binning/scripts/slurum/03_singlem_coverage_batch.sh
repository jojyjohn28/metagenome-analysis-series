#!/bin/bash
#SBATCH --job-name=singlem_coverage
#SBATCH --output=logs/singlem_coverage_%j.out
#SBATCH --error=logs/singlem_coverage_%j.err
#SBATCH --time=08:00:00
#SBATCH --cpus-per-task=96
#SBATCH --mem=128G
#SBATCH --partition=compute

# SingleM MAG Coverage Analysis
# Author: github.com/jojyjohn28
# Description: Calculate MAG detection and coverage in samples using SingleM
# Usage: sbatch 03_singlem_coverage_batch.sh

set -e  # Exit on error

# ==================== CONFIGURATION ====================

# Directories
CLEAN_READS_DIR="/path/to/clean_reads"
MAG_DIR="/path/to/metawrap_binning/sample1/BIN_REFINEMENT/metawrap_50_10_bins"
OUTPUT_DIR="singlem_results"

# Sample list
SAMPLES=(
    "sample1"
    "sample2"
    "sample3"
)

# SingleM parameters
THREADS=${SLURM_CPUS_PER_TASK:-96}

# ==================== SETUP ====================

mkdir -p ${OUTPUT_DIR}
mkdir -p logs

# Load environment
module load anaconda3
source activate metawrap

# Verify SingleM is installed
if ! command -v singlem &> /dev/null; then
    echo "ERROR: SingleM not found. Install with: conda install -c bioconda singlem"
    exit 1
fi

echo "========================================="
echo "  SingleM MAG Coverage Analysis"
echo "========================================="
echo "Job ID: ${SLURM_JOB_ID}"
echo "Node: ${SLURMD_NODENAME}"
echo "CPUs: ${THREADS}"
echo "Samples: ${#SAMPLES[@]}"
echo "MAG directory: ${MAG_DIR}"
echo "Start time: $(date)"
echo ""

# ==================== STEP 1: ANALYZE SAMPLES ====================

echo "Step 1: Analyzing samples with SingleM pipe..."
echo "----------------------------------------------"

SAMPLE_OTU_TABLES=""

for sample in "${SAMPLES[@]}"; do
    echo "Processing ${sample}..."
    
    R1="${CLEAN_READS_DIR}/${sample}_R1.fastq.gz"
    R2="${CLEAN_READS_DIR}/${sample}_R2.fastq.gz"
    
    # Check if files exist
    if [ ! -f "${R1}" ] || [ ! -f "${R2}" ]; then
        echo "  WARNING: Reads not found for ${sample}, skipping..."
        continue
    fi
    
    # Run SingleM pipe
    singlem pipe \
        --coupled ${R1} ${R2} \
        --otu-table ${OUTPUT_DIR}/${sample}_otu_table.tsv \
        --threads ${THREADS} \
        2>&1 | tee ${OUTPUT_DIR}/${sample}_singlem.log
    
    if [ $? -eq 0 ]; then
        echo "  ✓ ${sample} completed"
        SAMPLE_OTU_TABLES="${SAMPLE_OTU_TABLES} ${OUTPUT_DIR}/${sample}_otu_table.tsv"
    else
        echo "  ✗ ${sample} failed"
    fi
done

echo ""

# ==================== STEP 2: ANALYZE MAGs ====================

echo "Step 2: Analyzing MAGs with SingleM pipe..."
echo "-------------------------------------------"

# Get all MAG files
MAG_FILES=$(ls ${MAG_DIR}/*.fa)
MAG_COUNT=$(echo ${MAG_FILES} | wc -w)

echo "Found ${MAG_COUNT} MAG files"

singlem pipe \
    --genome-fasta-files ${MAG_FILES} \
    --otu-table ${OUTPUT_DIR}/mags_otu_table.tsv \
    --threads ${THREADS} \
    2>&1 | tee ${OUTPUT_DIR}/mags_singlem.log

if [ $? -eq 0 ]; then
    echo "✓ MAG analysis completed"
else
    echo "✗ MAG analysis failed"
    exit 1
fi

echo ""

# ==================== STEP 3: APPRAISE MAG COVERAGE ====================

echo "Step 3: Appraising MAG coverage in samples..."
echo "---------------------------------------------"

singlem appraise \
    --metagenome-otu-tables ${SAMPLE_OTU_TABLES} \
    --genome-otu-tables ${OUTPUT_DIR}/mags_otu_table.tsv \
    --output-binned-otu-table ${OUTPUT_DIR}/binned_otus.tsv \
    --output-unbinned-otu-table ${OUTPUT_DIR}/unbinned_otus.tsv \
    --output-found-in-metagenome ${OUTPUT_DIR}/found_mags.tsv \
    2>&1 | tee ${OUTPUT_DIR}/appraise.log

if [ $? -eq 0 ]; then
    echo "✓ Appraisal completed"
else
    echo "✗ Appraisal failed"
    exit 1
fi

echo ""

# ==================== STEP 4: SUMMARIZE RESULTS ====================

echo "Step 4: Summarizing results..."
echo "------------------------------"

singlem summarise \
    --input-otu-tables ${SAMPLE_OTU_TABLES} \
    --output-otu-table ${OUTPUT_DIR}/summary_otu_table.tsv \
    2>&1 | tee ${OUTPUT_DIR}/summarise.log

echo ""

# ==================== ANALYSIS SUMMARY ====================

echo "Generating coverage summary..."

python3 << 'EOF'
import pandas as pd
import numpy as np

# Read binned OTUs (MAGs found in samples)
try:
    binned = pd.read_csv('singlem_results/binned_otus.tsv', sep='\t')
    print("\n" + "="*70)
    print("  SingleM MAG COVERAGE SUMMARY")
    print("="*70)
    
    # Count unique MAGs and samples
    unique_mags = binned['genome'].nunique()
    unique_samples = binned['sample'].nunique()
    
    print(f"\nMAGs detected: {unique_mags}")
    print(f"Samples analyzed: {unique_samples}")
    
    # Calculate coverage statistics per MAG
    mag_coverage = binned.groupby('genome').agg({
        'sample': 'count',
        'coverage': ['mean', 'min', 'max']
    }).round(2)
    
    print(f"\nMAG Detection Summary:")
    print(f"  MAGs found in all samples: {(mag_coverage[('sample', 'count')] == unique_samples).sum()}")
    print(f"  MAGs found in >50% samples: {(mag_coverage[('sample', 'count')] > unique_samples/2).sum()}")
    print(f"  MAGs found in only 1 sample: {(mag_coverage[('sample', 'count')] == 1).sum()}")
    
    print(f"\nCoverage Statistics:")
    print(f"  Mean coverage across all MAGs: {mag_coverage[('coverage', 'mean')].mean():.1f}%")
    print(f"  MAGs with >90% coverage: {(mag_coverage[('coverage', 'mean')] > 90).sum()}")
    print(f"  MAGs with >50% coverage: {(mag_coverage[('coverage', 'mean')] > 50).sum()}")
    print(f"  MAGs with <10% coverage: {(mag_coverage[('coverage', 'mean')] < 10).sum()}")
    
    print(f"\nTop 5 Most Covered MAGs:")
    top5 = binned.groupby('genome')['coverage'].mean().nlargest(5)
    for mag, cov in top5.items():
        print(f"  {mag}: {cov:.1f}%")
    
except FileNotFoundError:
    print("ERROR: binned_otus.tsv not found")

# Read unbinned OTUs (organisms not in MAGs)
try:
    unbinned = pd.read_csv('singlem_results/unbinned_otus.tsv', sep='\t')
    
    if len(unbinned) > 0:
        print(f"\n⚠ Unbinned Sequences: {len(unbinned)}")
        print(f"  These represent organisms NOT recovered in your MAGs")
        print(f"  Consider deeper sequencing or different binning approaches")
        
        # Show top unbinned taxa
        print(f"\n  Top 5 unbinned taxa:")
        top_unbinned = unbinned.groupby('taxonomy')['count'].sum().nlargest(5)
        for tax, count in top_unbinned.items():
            print(f"    {tax}: {count} sequences")
    else:
        print(f"\n✓ No unbinned sequences - all detected organisms are in MAGs!")
        
except FileNotFoundError:
    print("\nWARNING: unbinned_otus.tsv not found")

print("="*70)
EOF

echo ""

# ==================== OUTPUT FILES ====================

echo "Output files created:"
echo "  ${OUTPUT_DIR}/*_otu_table.tsv          - Per-sample OTU tables"
echo "  ${OUTPUT_DIR}/mags_otu_table.tsv       - MAG reference OTU table"
echo "  ${OUTPUT_DIR}/binned_otus.tsv          - MAGs found in samples"
echo "  ${OUTPUT_DIR}/unbinned_otus.tsv        - Sequences not in MAGs"
echo "  ${OUTPUT_DIR}/found_mags.tsv           - MAG detection matrix"
echo "  ${OUTPUT_DIR}/summary_otu_table.tsv    - Overall summary"
echo ""

echo "========================================="
echo "  SingleM Analysis Complete!"
echo "========================================="
echo "End time: $(date)"
echo ""
echo "Next steps:"
echo "  1. Visualize coverage: python scripts/analysis/visualize_singlem_coverage.py"
echo "  2. Combine with CoverM: python scripts/analysis/combine_abundance_coverage.py"
