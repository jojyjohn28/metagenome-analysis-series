#!/bin/bash
# MetaWRAP complete pipeline

# Variables
SAMPLE="sample1"
R1="reads/${SAMPLE}_R1.fastq"
R2="reads/${SAMPLE}_R2.fastq"
THREADS=16

# Step 1: Read QC
metawrap read_qc \
    -1 $R1 \
    -2 $R2 \
    -t $THREADS \
    -o READ_QC

# Step 2: Assembly
metawrap assembly \
    -1 READ_QC/final_pure_reads_1.fastq \
    -2 READ_QC/final_pure_reads_2.fastq \
    -m 200 \
    -t $THREADS \
    --metaspades \
    -o ASSEMBLY

# Step 3: Binning (all 3 methods!)
metawrap binning \
    -o INITIAL_BINNING \
    -t $THREADS \
    -a ASSEMBLY/final_assembly.fasta \
    --metabat2 \
    --maxbin2 \
    --concoct \
    READ_QC/final_pure_reads_1.fastq \
    READ_QC/final_pure_reads_2.fastq

# Step 4: Bin refinement
metawrap bin_refinement \
    -o BIN_REFINEMENT \
    -t $THREADS \
    -A INITIAL_BINNING/metabat2_bins/ \
    -B INITIAL_BINNING/maxbin2_bins/ \
    -C INITIAL_BINNING/concoct_bins/ \
    -c 50 \
    -x 10

# Step 5: Reassemble bins
metawrap reassemble_bins \
    -o BIN_REASSEMBLY \
    -1 READ_QC/final_pure_reads_1.fastq \
    -2 READ_QC/final_pure_reads_2.fastq \
    -t $THREADS \
    -m 800 \
    -c 50 \
    -x 10 \
    -b BIN_REFINEMENT/metawrap_50_10_bins

# Step 6: Quantify bins
metawrap quant_bins \
    -b BIN_REASSEMBLY/reassembled_bins \
    -o QUANT_BINS \
    -a ASSEMBLY/final_assembly.fasta \
    READ_QC/final_pure_reads_*.fastq

# Step 7: Taxonomic classification
metawrap classify_bins \
    -b BIN_REASSEMBLY/reassembled_bins \
    -o BIN_CLASSIFICATION \
    -t $THREADS

# Step 8: Functional annotation
metawrap annotate_bins \
    -o FUNCT_ANNOT \
    -t $THREADS \
    -b BIN_REASSEMBLY/reassembled_bins

echo "✓ MetaWRAP pipeline complete!"

