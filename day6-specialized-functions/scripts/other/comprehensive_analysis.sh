#!/bin/bash
# comprehensive_analysis.sh

GENOME="genome.fa"
GBK="genome.gbk"
PROTEINS="proteins.faa"
CPUS=8

# 1. Secondary metabolites
echo "=== antiSMASH: BGCs ==="
antismash --output-dir antismash_out --cpus $CPUS $GBK

# 2. AMR genes
echo "=== CARD-RGI: AMR ==="
rgi main -i $PROTEINS -o rgi_out -t protein --num_threads $CPUS

echo "=== ABRicate: AMR screening ==="
abricate $GENOME > abricate_out.tab

# 3. CAZymes
echo "=== dbCAN: CAZymes ==="
run_dbcan $PROTEINS protein --out_dir dbcan_out --tools all --threads $CPUS

# 4. Prophages
echo "=== VirSorter2: Prophages ==="
virsorter run -i $GENOME -w virsorter2_out -j $CPUS all

# 5. CRISPR
echo "=== MinCED: CRISPR ==="
minced $GENOME crispr_out.txt

# 6. Mobile elements
echo "=== Integron Finder ==="
integron_finder --cpu $CPUS $GENOME

# 7. Protein domains
echo "=== InterProScan: Domains ==="
interproscan.sh -i $PROTEINS -o interproscan_out.tsv --cpu $CPUS

echo "✓ Complete analysis finished!"
