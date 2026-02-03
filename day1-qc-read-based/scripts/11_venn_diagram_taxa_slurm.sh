#!/bin/bash
#SBATCH --job-name=taxa_comparison
#SBATCH --output=logs/slurm/taxa_comparison_%j.out
#SBATCH --error=logs/slurm/taxa_comparison_%j.err
#SBATCH --time=01:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --partition=compute

# Script: 11_venn_diagram_taxa_slurm.sh
# Description: Compare detected taxa across different taxonomic profilers (SLURM version)
# Author: github.com/jojyjohn28
# Usage: sbatch 11_venn_diagram_taxa_slurm.sh

echo "Starting taxa comparison analysis..."
echo "Job ID: ${SLURM_JOB_ID}"
echo "Running on node: ${SLURM_NODELIST}"

# Create log directory
mkdir -p logs/slurm

echo "Extracting genus-level taxa from each tool..."

# Extract genus-level taxa from each tool
cut -f1 taxonomy/kaiju/all_samples_genus.tsv | tail -n +2 | sort -u > kaiju_genera.txt
cut -f1 taxonomy/kraken2/bracken_genus_combined.txt | tail -n +2 | sort -u > kraken2_genera.txt
cut -f1 taxonomy/motus/merged_profiles.txt | tail -n +2 | sort -u > motus_genera.txt

echo "Finding overlaps..."

# Find pairwise overlaps
comm -12 kaiju_genera.txt kraken2_genera.txt > overlap_kaiju_kraken2.txt
comm -12 kaiju_genera.txt motus_genera.txt > overlap_kaiju_motus.txt
comm -12 kraken2_genera.txt motus_genera.txt > overlap_kraken2_motus.txt

# Find unique to each tool
comm -23 kaiju_genera.txt kraken2_genera.txt | comm -23 - motus_genera.txt > unique_kaiju.txt
comm -13 kaiju_genera.txt kraken2_genera.txt | comm -23 - motus_genera.txt > unique_kraken2.txt
comm -13 kaiju_genera.txt motus_genera.txt | comm -13 kraken2_genera.txt - > unique_motus.txt

# Find three-way overlap
comm -12 kaiju_genera.txt kraken2_genera.txt | comm -12 - motus_genera.txt > overlap_all_three.txt

# Generate summary statistics
echo ""
echo "=== Taxa Detection Summary ==="
echo "Kaiju only: $(wc -l < unique_kaiju.txt) genera"
echo "Kraken2 only: $(wc -l < unique_kraken2.txt) genera"
echo "mOTUs only: $(wc -l < unique_motus.txt) genera"
echo ""
echo "Kaiju & Kraken2: $(wc -l < overlap_kaiju_kraken2.txt) genera"
echo "Kaiju & mOTUs: $(wc -l < overlap_kaiju_motus.txt) genera"
echo "Kraken2 & mOTUs: $(wc -l < overlap_kraken2_motus.txt) genera"
echo ""
echo "All three tools: $(wc -l < overlap_all_three.txt) genera"
echo ""
echo "Total unique genera detected:"
echo "  Kaiju: $(wc -l < kaiju_genera.txt)"
echo "  Kraken2: $(wc -l < kraken2_genera.txt)"
echo "  mOTUs: $(wc -l < motus_genera.txt)"

# Save summary to file
cat > taxa_comparison_summary.txt <<EOF
Taxa Detection Comparison Summary
==================================
Job ID: ${SLURM_JOB_ID}
Date: $(date)

Unique to each tool:
  Kaiju only: $(wc -l < unique_kaiju.txt) genera
  Kraken2 only: $(wc -l < unique_kraken2.txt) genera
  mOTUs only: $(wc -l < unique_motus.txt) genera

Pairwise overlaps:
  Kaiju & Kraken2: $(wc -l < overlap_kaiju_kraken2.txt) genera
  Kaiju & mOTUs: $(wc -l < overlap_kaiju_motus.txt) genera
  Kraken2 & mOTUs: $(wc -l < overlap_kraken2_motus.txt) genera

Three-way overlap:
  All three tools: $(wc -l < overlap_all_three.txt) genera

Total unique genera per tool:
  Kaiju: $(wc -l < kaiju_genera.txt)
  Kraken2: $(wc -l < kraken2_genera.txt)
  mOTUs: $(wc -l < motus_genera.txt)
EOF

echo "Analysis complete!"
echo "Summary saved to: taxa_comparison_summary.txt"
