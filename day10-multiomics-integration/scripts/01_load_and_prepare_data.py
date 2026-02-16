#!/usr/bin/env python3
"""
Script: 01_load_and_prepare_data.py
Description: Loads metagenomics and metatranscriptomics data, aligns gene IDs,
             and prepares datasets for integration analysis.
             
Input:
    - data/gene_abundance_table.tsv (metagenomics gene counts)
    - data/transcript_counts.tsv (metatranscriptomics transcript counts)
    
Output:
    - Prints summary statistics
    - Aligned datasets stored in memory for downstream analysis
    
What it does:
    1. Loads MG and MTX count tables
    2. Identifies common genes between datasets
    3. Filters to keep only shared genes
    4. Reports dataset dimensions and overlap
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from scipy import stats

# Set style
sns.set_style("whitegrid")
plt.rcParams['figure.figsize'] = (12, 8)

def main():
    print("=" * 70)
    print("STEP 1: LOADING AND PREPARING DATA")
    print("=" * 70)
    
    # Load metagenomics gene abundance table
    print("\n[1/4] Loading metagenomics data...")
    mg_genes = pd.read_csv('data/gene_abundance_table.tsv', sep='\t', index_col=0)
    print(f"      Metagenomics: {mg_genes.shape[0]} genes × {mg_genes.shape[1]} samples")
    
    # Load metatranscriptomics transcript counts
    print("\n[2/4] Loading metatranscriptomics data...")
    mtx_transcripts = pd.read_csv('data/transcript_counts.tsv', sep='\t', index_col=0)
    print(f"      Metatranscriptomics: {mtx_transcripts.shape[0]} transcripts × {mtx_transcripts.shape[1]} samples")
    
    # Check sample names
    print("\n[3/4] Checking sample names...")
    print(f"      MG samples: {mg_genes.columns.tolist()}")
    print(f"      MTX samples: {mtx_transcripts.columns.tolist()}")
    
    # Align gene IDs (keep only common genes)
    print("\n[4/4] Aligning gene IDs...")
    common_genes = mg_genes.index.intersection(mtx_transcripts.index)
    print(f"      Common genes between MG and MTX: {len(common_genes)}")
    print(f"      MG-specific genes: {len(mg_genes.index) - len(common_genes)}")
    print(f"      MTX-specific genes: {len(mtx_transcripts.index) - len(common_genes)}")
    
    mg_genes = mg_genes.loc[common_genes]
    mtx_transcripts = mtx_transcripts.loc[common_genes]
    
    # Save aligned data
    mg_genes.to_csv('results/mg_genes_aligned.csv')
    mtx_transcripts.to_csv('results/mtx_transcripts_aligned.csv')
    
    print("\n✓ Data loading and preparation complete!")
    print(f"✓ Aligned datasets saved to results/ directory")
    print("=" * 70)
    
    return mg_genes, mtx_transcripts

if __name__ == "__main__":
    mg_genes, mtx_transcripts = main()
