#!/bin/bash
#SBATCH --job-name=metawrap_binning
#SBATCH --output=logs/metawrap_binning_%A_%a.out
#SBATCH --error=logs/metawrap_binning_%A_%a.err
#SBATCH --array=1-3  # Adjust based on number of samples
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=96
#SBATCH --mem=256G
#SBATCH --partition=compute

# MetaWRAP Binning Batch Script
# Author: github.com/jojyjohn28
# Description: Run MetaWRAP binning (all 3 binners + refinement) on multiple samples
# Usage: sbatch 01_metawrap_binning_batch.sh

set -e  # Exit on error

# ==================== CONFIGURATION ====================

# Directories
ASSEMBLY_DIR="/path/to/assembly_spades_results"
CLEAN_READS_DIR="/path/to/clean_reads"
OUTPUT_BASE="/path/to/metawrap_binning"

# Sample list (one sample per line)
SAMPLE_LIST="sample_list.txt"

# MetaWRAP parameters
THREADS=${SLURM_CPUS_PER_TASK:-96}
MIN_CONTIG_LENGTH=1500

# Refinement parameters
MIN_COMPLETION=50
MAX_CONTAMINATION=10

# ==================== SETUP ====================

# Create directories
mkdir -p ${OUTPUT_BASE}/logs
mkdir -p logs

# Load environment
module load anaconda3
source activate metawrap

# Get sample name from array index
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" ${SAMPLE_LIST})

echo "========================================="
echo "  MetaWRAP Binning Pipeline"
echo "========================================="
echo "Job ID: ${SLURM_JOB_ID}"
echo "Array Task ID: ${SLURM_ARRAY_TASK_ID}"
echo "Sample: ${SAMPLE}"
echo "Node: ${SLURMD_NODENAME}"
echo "CPUs: ${THREADS}"
echo "Start time: $(date)"
echo ""

# ==================== STEP 1: INITIAL BINNING ====================

echo "Step 1: Initial Binning (MetaBAT2 + MaxBin2 + CONCOCT)"
echo "--------------------------------------------------------"

CONTIGS="${ASSEMBLY_DIR}/${SAMPLE}_assembly/contigs.fasta"
READS_R1="${CLEAN_READS_DIR}/${SAMPLE}_R1.fastq"
READS_R2="${CLEAN_READS_DIR}/${SAMPLE}_R2.fastq"

# Check input files exist
if [ ! -f "${CONTIGS}" ]; then
    echo "ERROR: Contigs not found: ${CONTIGS}"
    exit 1
fi

if [ ! -f "${READS_R1}" ] || [ ! -f "${READS_R2}" ]; then
    echo "ERROR: Clean reads not found for ${SAMPLE}"
    exit 1
fi

# Run MetaWRAP binning (all-in-one)
metawrap binning \
    -o ${OUTPUT_BASE}/${SAMPLE}/INITIAL_BINNING \
    -t ${THREADS} \
    -a ${CONTIGS} \
    --metabat2 \
    --maxbin2 \
    --concoct \
    ${READS_R1} ${READS_R2} \
    -m ${MIN_CONTIG_LENGTH} \
    --run-checkm \
    2>&1 | tee ${OUTPUT_BASE}/logs/${SAMPLE}_initial_binning.log

if [ $? -eq 0 ]; then
    echo "✓ Initial binning completed for ${SAMPLE}"
    
    # Count bins
    metabat_bins=$(ls ${OUTPUT_BASE}/${SAMPLE}/INITIAL_BINNING/metabat2_bins/*.fa 2>/dev/null | wc -l)
    maxbin_bins=$(ls ${OUTPUT_BASE}/${SAMPLE}/INITIAL_BINNING/maxbin2_bins/*.fasta 2>/dev/null | wc -l)
    concoct_bins=$(ls ${OUTPUT_BASE}/${SAMPLE}/INITIAL_BINNING/concoct_bins/*.fa 2>/dev/null | wc -l)
    
    echo "  MetaBAT2: ${metabat_bins} bins"
    echo "  MaxBin2:  ${maxbin_bins} bins"
    echo "  CONCOCT:  ${concoct_bins} bins"
    echo "  Total:    $((metabat_bins + maxbin_bins + concoct_bins)) bins"
else
    echo "✗ Initial binning failed for ${SAMPLE}"
    exit 1
fi

echo ""

# ==================== STEP 2: BIN REFINEMENT ====================

echo "Step 2: Bin Refinement"
echo "----------------------"

metawrap bin_refinement \
    -o ${OUTPUT_BASE}/${SAMPLE}/BIN_REFINEMENT \
    -t ${THREADS} \
    -A ${OUTPUT_BASE}/${SAMPLE}/INITIAL_BINNING/metabat2_bins/ \
    -B ${OUTPUT_BASE}/${SAMPLE}/INITIAL_BINNING/maxbin2_bins/ \
    -C ${OUTPUT_BASE}/${SAMPLE}/INITIAL_BINNING/concoct_bins/ \
    -c ${MIN_COMPLETION} \
    -x ${MAX_CONTAMINATION} \
    -m ${MIN_CONTIG_LENGTH} \
    2>&1 | tee ${OUTPUT_BASE}/logs/${SAMPLE}_refinement.log

if [ $? -eq 0 ]; then
    echo "✓ Bin refinement completed for ${SAMPLE}"
    
    # Count refined bins
    refined_bins=$(ls ${OUTPUT_BASE}/${SAMPLE}/BIN_REFINEMENT/metawrap_${MIN_COMPLETION}_${MAX_CONTAMINATION}_bins/*.fa 2>/dev/null | wc -l)
    echo "  Refined bins: ${refined_bins}"
    
    # Show quality stats
    if [ -f "${OUTPUT_BASE}/${SAMPLE}/BIN_REFINEMENT/metawrap_${MIN_COMPLETION}_${MAX_CONTAMINATION}_bins.stats" ]; then
        echo ""
        echo "Quality Summary:"
        head -n 6 ${OUTPUT_BASE}/${SAMPLE}/BIN_REFINEMENT/metawrap_${MIN_COMPLETION}_${MAX_CONTAMINATION}_bins.stats
    fi
else
    echo "✗ Bin refinement failed for ${SAMPLE}"
    exit 1
fi

echo ""

# ==================== STEP 3: BIN QUANTIFICATION ====================

echo "Step 3: Bin Quantification"
echo "--------------------------"

metawrap quant_bins \
    -b ${OUTPUT_BASE}/${SAMPLE}/BIN_REFINEMENT/metawrap_${MIN_COMPLETION}_${MAX_CONTAMINATION}_bins \
    -o ${OUTPUT_BASE}/${SAMPLE}/QUANT_BINS \
    -a ${CONTIGS} \
    ${READS_R1} ${READS_R2} \
    -t ${THREADS} \
    2>&1 | tee ${OUTPUT_BASE}/logs/${SAMPLE}_quant.log

if [ $? -eq 0 ]; then
    echo "✓ Bin quantification completed for ${SAMPLE}"
else
    echo "✗ Bin quantification failed for ${SAMPLE}"
fi

echo ""
echo "========================================="
echo "  MetaWRAP Pipeline Complete!"
echo "========================================="
echo "Sample: ${SAMPLE}"
echo "Output: ${OUTPUT_BASE}/${SAMPLE}/"
echo "End time: $(date)"
echo ""

# ==================== CLEANUP ====================

# Optional: Remove intermediate work files to save space
# Uncomment if disk space is limited
# rm -rf ${OUTPUT_BASE}/${SAMPLE}/INITIAL_BINNING/work_files/

echo "Next step: Run CoverM for abundance analysis"
echo "  sbatch 02_coverm_abundance_batch.sh"
