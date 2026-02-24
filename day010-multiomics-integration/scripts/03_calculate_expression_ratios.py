#!/usr/bin/env python3
"""
Script: 03_calculate_expression_ratios.py
Description: Calculates RNA/DNA expression ratios for each gene to identify
             which genes are more (or less) expressed than expected based on
             their genomic abundance.
             
Input:
    - results/mg_genes_cpm.csv (normalized DNA abundance)
    - results/mtx_transcripts_cpm.csv (normalized RNA abundance)
    
Output:
    - results/expression_ratios.csv
    - results/highly_expressed_genes.csv
    - results/under_expressed_genes.csv
    
What it does:
    1. Calculates log2(RNA/DNA) for each gene and sample
    2. Computes mean expression ratio across samples
    3. Identifies highly expressed genes (ratio > 2)
    4. Identifies under-expressed genes (ratio < -2)
    5. Saves results for visualization
"""

import pandas as pd
import numpy as np

def main():
    print("=" * 70)
    print("STEP 3: CALCULATING EXPRESSION RATIOS")
    print("=" * 70)
    
    # Load normalized data
    print("\n[1/5] Loading normalized data...")
    mg_cpm = pd.read_csv('results/mg_genes_cpm.csv', index_col=0)
    mtx_cpm = pd.read_csv('results/mtx_transcripts_cpm.csv', index_col=0)
    
    common_genes = mg_cpm.index.intersection(mtx_cpm.index)
    print(f"      Processing {len(common_genes)} common genes")
    
    # Match MG and MTX samples (assuming they have corresponding names)
    print("\n[2/5] Matching sample pairs...")
    mg_samples = [col for col in mg_cpm.columns if 'MG' in col]
    mtx_samples = [col.replace('MG', 'MTX') for col in mg_samples]
    print(f"      Found {len(mg_samples)} sample pairs")
    
    # Calculate RNA/DNA ratios for each sample pair
    # Add pseudocount to avoid division by zero
    pseudocount = 1
    
    print("\n[3/5] Calculating log2(RNA/DNA) ratios...")
    expression_ratios = pd.DataFrame(index=common_genes)
    
    for mg_col, mtx_col in zip(mg_samples, mtx_samples):
        sample_id = mg_col.replace('_MG', '')
        expression_ratios[sample_id] = np.log2(
            (mtx_cpm[mtx_col] + pseudocount) / (mg_cpm[mg_col] + pseudocount)
        )
    
    # Calculate mean expression ratio across samples
    expression_ratios['Mean_Log2_Ratio'] = expression_ratios.mean(axis=1)
    expression_ratios['StdDev'] = expression_ratios.iloc[:, :-1].std(axis=1)
    
    # Save results
    expression_ratios.to_csv('results/expression_ratios.csv')
    
    # Summary statistics
    print("\n[4/5] Computing summary statistics...")
    highly_expressed_count = (expression_ratios['Mean_Log2_Ratio'] > 2).sum()
    moderately_expressed_count = (
        (expression_ratios['Mean_Log2_Ratio'] > 0) & 
        (expression_ratios['Mean_Log2_Ratio'] < 2)
    ).sum()
    under_expressed_count = (expression_ratios['Mean_Log2_Ratio'] < 0).sum()
    
    print(f"\nExpression Ratio Summary:")
    print(f"  Highly expressed genes (log2 ratio > 2):    {highly_expressed_count:6d} ({highly_expressed_count/len(common_genes)*100:5.1f}%)")
    print(f"  Moderately expressed (0 < log2 ratio < 2):  {moderately_expressed_count:6d} ({moderately_expressed_count/len(common_genes)*100:5.1f}%)")
    print(f"  Under-expressed (log2 ratio < 0):           {under_expressed_count:6d} ({under_expressed_count/len(common_genes)*100:5.1f}%)")
    print(f"  Mean expression ratio: {expression_ratios['Mean_Log2_Ratio'].mean():.2f}")
    print(f"  Median expression ratio: {expression_ratios['Mean_Log2_Ratio'].median():.2f}")
    
    # Extract genes with extreme expression patterns
    print("\n[5/5] Identifying genes with extreme expression...")
    highly_expressed = expression_ratios[
        expression_ratios['Mean_Log2_Ratio'] > 2
    ].sort_values('Mean_Log2_Ratio', ascending=False)
    
    under_expressed = expression_ratios[
        expression_ratios['Mean_Log2_Ratio'] < -2
    ].sort_values('Mean_Log2_Ratio')
    
    print(f"\nTop 10 Highly Expressed Genes:")
    print(highly_expressed.head(10)[['Mean_Log2_Ratio', 'StdDev']])
    
    print(f"\nTop 10 Under-Expressed Genes:")
    print(under_expressed.head(10)[['Mean_Log2_Ratio', 'StdDev']])
    
    # Save to file
    highly_expressed.to_csv('results/highly_expressed_genes.csv')
    under_expressed.to_csv('results/under_expressed_genes.csv')
    
    print("\n✓ Expression ratio calculation complete!")
    print(f"✓ Results saved to results/ directory")
    print("=" * 70)
    
    return expression_ratios

if __name__ == "__main__":
    expression_ratios = main()
