#!/bin/bash

# MetaWRAP Binning Loop for Desktop/Laptop
# Author: github.com/jojyjohn28
# Description: Process multiple samples sequentially on a desktop/laptop
# Usage: bash desktop_metawrap_loop.sh

set -e  # Exit on error

# ==================== CONFIGURATION ====================

# Directories
ASSEMBLY_DIR="../day2-assembly/results"
CLEAN_READS_DIR="../day1-qc/results/trimmed"
OUTPUT_DIR="binning_results"

# Sample list
SAMPLES=(
    "sample1"
    "sample2"
    "sample3"
)

# Hardware settings (adjust for your system)
THREADS=8  # Use: $(nproc) - 2 to auto-detect and leave 2 cores for system
MEMORY="32G"  # Adjust based on your RAM

# MetaWRAP parameters
MIN_CONTIG_LENGTH=1500
MIN_COMPLETION=50
MAX_CONTAMINATION=10

# ==================== SETUP ====================

# Create directories
mkdir -p ${OUTPUT_DIR}/logs

# Activate conda environment
conda activate metawrap

# Check if MetaWRAP is installed
if ! command -v metawrap &> /dev/null; then
    echo "ERROR: MetaWRAP not found. Please install it first."
    exit 1
fi

echo "========================================="
echo "  MetaWRAP Desktop Processing Loop"
echo "========================================="
echo "Samples to process: ${#SAMPLES[@]}"
echo "Threads: ${THREADS}"
echo "Memory limit: ${MEMORY}"
echo "Start time: $(date)"
echo ""

# ==================== PROCESS EACH SAMPLE ====================

SUCCESS_COUNT=0
FAIL_COUNT=0

for i in "${!SAMPLES[@]}"; do
    SAMPLE="${SAMPLES[$i]}"
    SAMPLE_NUM=$((i + 1))
    
    echo ""
    echo "========================================="
    echo "  Processing Sample ${SAMPLE_NUM}/${#SAMPLES[@]}: ${SAMPLE}"
    echo "========================================="
    echo "Start time: $(date)"
    echo ""
    
    # Define paths
    CONTIGS="${ASSEMBLY_DIR}/${SAMPLE}/contigs.fasta"
    READS_R1="${CLEAN_READS_DIR}/${SAMPLE}_R1_paired.fastq.gz"
    READS_R2="${CLEAN_READS_DIR}/${SAMPLE}_R2_paired.fastq.gz"
    
    # Check input files
    if [ ! -f "${CONTIGS}" ]; then
        echo "ERROR: Contigs not found: ${CONTIGS}"
        echo "Skipping ${SAMPLE}..."
        FAIL_COUNT=$((FAIL_COUNT + 1))
        continue
    fi
    
    if [ ! -f "${READS_R1}" ] || [ ! -f "${READS_R2}" ]; then
        echo "ERROR: Clean reads not found for ${SAMPLE}"
        echo "Skipping ${SAMPLE}..."
        FAIL_COUNT=$((FAIL_COUNT + 1))
        continue
    fi
    
    # ==================== STEP 1: INITIAL BINNING ====================
    
    echo "Step 1/3: Initial Binning (MetaBAT2 + MaxBin2 + CONCOCT)"
    echo "-------------------------------------------------------"
    
    metawrap binning \
        -o ${OUTPUT_DIR}/${SAMPLE}/INITIAL_BINNING \
        -t ${THREADS} \
        -a ${CONTIGS} \
        --metabat2 \
        --maxbin2 \
        --concoct \
        ${READS_R1} ${READS_R2} \
        -m ${MIN_CONTIG_LENGTH} \
        --run-checkm \
        2>&1 | tee ${OUTPUT_DIR}/logs/${SAMPLE}_binning.log
    
    if [ $? -ne 0 ]; then
        echo "ERROR: Initial binning failed for ${SAMPLE}"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        continue
    fi
    
    # Count bins
    metabat_bins=$(ls ${OUTPUT_DIR}/${SAMPLE}/INITIAL_BINNING/metabat2_bins/*.fa 2>/dev/null | wc -l)
    maxbin_bins=$(ls ${OUTPUT_DIR}/${SAMPLE}/INITIAL_BINNING/maxbin2_bins/*.fasta 2>/dev/null | wc -l)
    concoct_bins=$(ls ${OUTPUT_DIR}/${SAMPLE}/INITIAL_BINNING/concoct_bins/*.fa 2>/dev/null | wc -l)
    total_bins=$((metabat_bins + maxbin_bins + concoct_bins))
    
    echo ""
    echo "Initial binning results:"
    echo "  MetaBAT2: ${metabat_bins} bins"
    echo "  MaxBin2:  ${maxbin_bins} bins"
    echo "  CONCOCT:  ${concoct_bins} bins"
    echo "  Total:    ${total_bins} bins"
    echo ""
    
    if [ ${total_bins} -eq 0 ]; then
        echo "WARNING: No bins recovered for ${SAMPLE}"
        echo "Check assembly quality and coverage depth"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        continue
    fi
    
    # ==================== STEP 2: BIN REFINEMENT ====================
    
    echo "Step 2/3: Bin Refinement"
    echo "------------------------"
    
    metawrap bin_refinement \
        -o ${OUTPUT_DIR}/${SAMPLE}/BIN_REFINEMENT \
        -t ${THREADS} \
        -A ${OUTPUT_DIR}/${SAMPLE}/INITIAL_BINNING/metabat2_bins/ \
        -B ${OUTPUT_DIR}/${SAMPLE}/INITIAL_BINNING/maxbin2_bins/ \
        -C ${OUTPUT_DIR}/${SAMPLE}/INITIAL_BINNING/concoct_bins/ \
        -c ${MIN_COMPLETION} \
        -x ${MAX_CONTAMINATION} \
        -m ${MIN_CONTIG_LENGTH} \
        2>&1 | tee ${OUTPUT_DIR}/logs/${SAMPLE}_refinement.log
    
    if [ $? -ne 0 ]; then
        echo "ERROR: Bin refinement failed for ${SAMPLE}"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        continue
    fi
    
    # Count refined bins
    refined_bins=$(ls ${OUTPUT_DIR}/${SAMPLE}/BIN_REFINEMENT/metawrap_${MIN_COMPLETION}_${MAX_CONTAMINATION}_bins/*.fa 2>/dev/null | wc -l)
    
    echo ""
    echo "Refinement results:"
    echo "  Input bins:   ${total_bins}"
    echo "  Refined bins: ${refined_bins}"
    echo ""
    
    # ==================== STEP 3: BIN QUANTIFICATION ====================
    
    echo "Step 3/3: Bin Quantification"
    echo "----------------------------"
    
    metawrap quant_bins \
        -b ${OUTPUT_DIR}/${SAMPLE}/BIN_REFINEMENT/metawrap_${MIN_COMPLETION}_${MAX_CONTAMINATION}_bins \
        -o ${OUTPUT_DIR}/${SAMPLE}/QUANT_BINS \
        -a ${CONTIGS} \
        ${READS_R1} ${READS_R2} \
        -t ${THREADS} \
        2>&1 | tee ${OUTPUT_DIR}/logs/${SAMPLE}_quant.log
    
    if [ $? -eq 0 ]; then
        echo "✓ Quantification completed"
    else
        echo "WARNING: Quantification failed (non-critical)"
    fi
    
    echo ""
    echo "✓ ${SAMPLE} processing complete!"
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    
    # ==================== SAMPLE SUMMARY ====================
    
    echo ""
    echo "Summary for ${SAMPLE}:"
    echo "---------------------"
    if [ -f "${OUTPUT_DIR}/${SAMPLE}/BIN_REFINEMENT/metawrap_${MIN_COMPLETION}_${MAX_CONTAMINATION}_bins.stats" ]; then
        echo ""
        head -n 6 ${OUTPUT_DIR}/${SAMPLE}/BIN_REFINEMENT/metawrap_${MIN_COMPLETION}_${MAX_CONTAMINATION}_bins.stats
    fi
    
    echo ""
    echo "End time: $(date)"
    
    # Optional: Clean up intermediate files to save disk space
    # Uncomment if running low on space
    # echo "Cleaning up intermediate files..."
    # rm -rf ${OUTPUT_DIR}/${SAMPLE}/INITIAL_BINNING/work_files/
    
done

# ==================== FINAL SUMMARY ====================

echo ""
echo "========================================="
echo "  Processing Complete!"
echo "========================================="
echo "Total samples: ${#SAMPLES[@]}"
echo "Successful:    ${SUCCESS_COUNT}"
echo "Failed:        ${FAIL_COUNT}"
echo ""
echo "End time: $(date)"
echo ""

if [ ${SUCCESS_COUNT} -gt 0 ]; then
    echo "Output directory: ${OUTPUT_DIR}"
    echo ""
    echo "Refined bins locations:"
    for sample in "${SAMPLES[@]}"; do
        refined_dir="${OUTPUT_DIR}/${sample}/BIN_REFINEMENT/metawrap_${MIN_COMPLETION}_${MAX_CONTAMINATION}_bins"
        if [ -d "${refined_dir}" ]; then
            bin_count=$(ls ${refined_dir}/*.fa 2>/dev/null | wc -l)
            echo "  ${sample}: ${refined_dir} (${bin_count} bins)"
        fi
    done
    echo ""
    echo "Next steps:"
    echo "  1. Run CoverM for abundance: bash desktop_coverm_abundance.sh"
    echo "  2. Run SingleM for coverage: bash desktop_singlem_coverage.sh"
    echo "  3. Visualize results: python ../scripts/analysis/visualize_mag_abundance.py"
fi

# ==================== SYSTEM RESOURCES ====================

echo ""
echo "System resource usage:"
df -h ${OUTPUT_DIR} | tail -1 | awk '{print "  Disk usage: "$3" / "$2" ("$5" used)"}'
echo ""
