#!/usr/bin/env python3
"""
Script: 02_normalize_data.py
Description: Normalizes metagenomics and metatranscriptomics count data to 
             CPM (counts per million) for fair comparison across samples.
             
Input:
    - results/mg_genes_aligned.csv
    - results/mtx_transcripts_aligned.csv
    
Output:
    - results/mg_genes_cpm.csv
    - results/mtx_transcripts_cpm.csv
    
What it does:
    1. Loads aligned count matrices
    2. Calculates CPM normalization (accounts for sequencing depth)
    3. Validates normalization (each sample sums to 1 million)
    4. Saves normalized data for downstream analysis
"""

import pandas as pd
import numpy as np

def normalize_cpm(df):
    """
    Convert counts to counts per million (CPM)
    
    Formula: CPM = (count / total_counts_in_sample) × 1,000,000
    
    Args:
        df: DataFrame with genes as rows, samples as columns
        
    Returns:
        DataFrame with CPM-normalized values
    """
    totals = df.sum(axis=0)
    cpm = (df / totals) * 1e6
    return cpm

def main():
    print("=" * 70)
    print("STEP 2: DATA NORMALIZATION")
    print("=" * 70)
    
    # Load aligned data
    print("\n[1/4] Loading aligned count data...")
    mg_genes = pd.read_csv('results/mg_genes_aligned.csv', index_col=0)
    mtx_transcripts = pd.read_csv('results/mtx_transcripts_aligned.csv', index_col=0)
    
    print(f"      Loaded {mg_genes.shape[0]} genes, {mg_genes.shape[1]} samples")
    
    # Calculate sequencing depth
    print("\n[2/4] Calculating sequencing depth...")
    mg_depth = mg_genes.sum(axis=0)
    mtx_depth = mtx_transcripts.sum(axis=0)
    
    print(f"      MG sequencing depth:")
    print(f"        Mean: {mg_depth.mean():.0f} reads/sample")
    print(f"        Range: {mg_depth.min():.0f} - {mg_depth.max():.0f}")
    
    print(f"      MTX sequencing depth:")
    print(f"        Mean: {mtx_depth.mean():.0f} reads/sample")
    print(f"        Range: {mtx_depth.min():.0f} - {mtx_depth.max():.0f}")
    
    # Normalize both datasets
    print("\n[3/4] Normalizing to CPM...")
    mg_cpm = normalize_cpm(mg_genes)
    mtx_cpm = normalize_cpm(mtx_transcripts)
    
    # Validate normalization
    print("\n[4/4] Validating normalization...")
    mg_totals = mg_cpm.sum(axis=0)
    mtx_totals = mtx_cpm.sum(axis=0)
    
    print(f"      MG CPM totals: {mg_totals.min():.0f} - {mg_totals.max():.0f} (should all be ~1,000,000)")
    print(f"      MTX CPM totals: {mtx_totals.min():.0f} - {mtx_totals.max():.0f} (should all be ~1,000,000)")
    
    # Save normalized data
    mg_cpm.to_csv('results/mg_genes_cpm.csv')
    mtx_cpm.to_csv('results/mtx_transcripts_cpm.csv')
    
    print("\n✓ Normalization complete!")
    print(f"✓ Normalized data saved to results/ directory")
    print("=" * 70)
    
    return mg_cpm, mtx_cpm

if __name__ == "__main__":
    mg_cpm, mtx_cpm = main()
