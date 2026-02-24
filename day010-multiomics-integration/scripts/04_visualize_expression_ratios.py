#!/usr/bin/env python3
"""
Script: 04_visualize_expression_ratios.py
Description: Creates publication-quality visualizations of expression ratios
             including histograms, MA plots, and boxplots to understand
             gene expression patterns across samples.
             
Input:
    - results/expression_ratios.csv
    - results/mg_genes_cpm.csv
    - results/mtx_transcripts_cpm.csv
    
Output:
    - figures/expression_ratio_histogram.png
    - figures/ma_plot_expression.png
    - figures/expression_ratio_boxplot.png
    
What it does:
    1. Histogram: distribution of expression ratios across all genes
    2. MA plot: relationship between gene abundance and expression ratio
    3. Boxplot: expression ratio variability across samples
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

# Set style
sns.set_style("whitegrid")
plt.rcParams['figure.figsize'] = (12, 8)

def main():
    print("=" * 70)
    print("STEP 4: VISUALIZING EXPRESSION RATIOS")
    print("=" * 70)
    
    # Load data
    print("\n[1/4] Loading data...")
    expression_ratios = pd.read_csv('results/expression_ratios.csv', index_col=0)
    mg_cpm = pd.read_csv('results/mg_genes_cpm.csv', index_col=0)
    mtx_cpm = pd.read_csv('results/mtx_transcripts_cpm.csv', index_col=0)
    
    print(f"      Loaded {len(expression_ratios)} genes")
    
    # 1. Histogram of expression ratios
    print("\n[2/4] Creating histogram of expression ratios...")
    plt.figure(figsize=(10, 6))
    plt.hist(expression_ratios['Mean_Log2_Ratio'], bins=50, 
             color='steelblue', edgecolor='black', alpha=0.7)
    plt.axvline(x=0, color='red', linestyle='--', linewidth=2, label='Equal expression')
    plt.axvline(x=2, color='orange', linestyle='--', linewidth=2, label='Highly expressed')
    plt.xlabel('Log2(RNA/DNA) Ratio', fontsize=12)
    plt.ylabel('Number of Genes', fontsize=12)
    plt.title('Distribution of Gene Expression Ratios', fontsize=14, fontweight='bold')
    plt.legend()
    plt.tight_layout()
    plt.savefig('figures/expression_ratio_histogram.png', dpi=300)
    plt.close()
    print("      ✓ Saved: figures/expression_ratio_histogram.png")
    
    # 2. MA plot (mean abundance vs expression ratio)
    print("\n[3/4] Creating MA plot...")
    mean_abundance = (mg_cpm.mean(axis=1) + mtx_cpm.mean(axis=1)) / 2
    
    plt.figure(figsize=(10, 6))
    plt.scatter(np.log10(mean_abundance + 1), 
               expression_ratios['Mean_Log2_Ratio'],
               alpha=0.3, s=10, c='steelblue')
    plt.axhline(y=0, color='red', linestyle='--', linewidth=2, label='Equal expression')
    plt.axhline(y=2, color='orange', linestyle='--', linewidth=1, label='Highly expressed')
    plt.axhline(y=-2, color='orange', linestyle='--', linewidth=1, label='Under-expressed')
    plt.xlabel('Log10(Mean Abundance)', fontsize=12)
    plt.ylabel('Log2(RNA/DNA) Ratio', fontsize=12)
    plt.title('MA Plot: Abundance vs Expression Ratio', fontsize=14, fontweight='bold')
    plt.legend()
    plt.tight_layout()
    plt.savefig('figures/ma_plot_expression.png', dpi=300)
    plt.close()
    print("      ✓ Saved: figures/ma_plot_expression.png")
    
    # 3. Box plot across samples
    print("\n[4/4] Creating boxplot across samples...")
    plt.figure(figsize=(12, 6))
    
    # Remove Mean_Log2_Ratio and StdDev columns for boxplot
    sample_columns = [col for col in expression_ratios.columns 
                     if col not in ['Mean_Log2_Ratio', 'StdDev']]
    expression_ratios[sample_columns].boxplot()
    
    plt.xticks(rotation=45, ha='right')
    plt.ylabel('Log2(RNA/DNA) Ratio', fontsize=12)
    plt.title('Expression Ratios Across Samples', fontsize=14, fontweight='bold')
    plt.axhline(y=0, color='red', linestyle='--', alpha=0.5, label='Equal expression')
    plt.legend()
    plt.tight_layout()
    plt.savefig('figures/expression_ratio_boxplot.png', dpi=300)
    plt.close()
    print("      ✓ Saved: figures/expression_ratio_boxplot.png")
    
    print("\n✓ Visualization complete!")
    print(f"✓ All figures saved to figures/ directory")
    print("=" * 70)

if __name__ == "__main__":
    main()
